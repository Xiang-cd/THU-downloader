# 清华邮箱相关接口

import requests
import gradio as gr
import os, json, time, re
import ast
import utils
import asyncio
import aiofiles
import shared
from aiohttp import ClientSession
import zipfile
from pathlib import Path
import asyncio
from subprocess import Popen, PIPE
import sys, signal

import logging
logging.basicConfig(filename=shared.LOG_FILE,
                    filemode='a',
                    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s')
logger = logging.getLogger(Path(__file__).name)
logger.setLevel(shared.LOG_LEVEL)

global_email_list = []
list_url = "https://mails.tsinghua.edu.cn/coremail/XT3/mbox/getListDatas.jsp?sid={sid}&fid=1&nav_type=system&inbox=true&page_no={page_num}" # old version
list_url = "https://mails.tsinghua.edu.cn/coremail/s/json?sid={sid}&func=mbox%3AlistMessages"
email_url = "https://mails.tsinghua.edu.cn/coremail/XT3/mbox/viewMailHTML.jsp?mid={mid}&partId=0&isSearch=&priority=&supportSMIME=&striptTrs=true&mboxa=&sandbox=1"
download_url = "https://mails.tsinghua.edu.cn/coremail/XT3/mbox/allDownload.jsp?sid={sid}&mid={mid}&mboxa=" # old version
download_url = "https://mails.tsinghua.edu.cn/coremail/mbox-data/?mode=download&mid={mid}&mboxa="

login_process = None
global_user_name = None


def email_login_stage1(username, password):
    global login_process, global_user_name
    if login_process is not None:
        try:
            os.killpg(os.getpgid(login_process.pid), signal.SIGTERM)
        except:
            pass
    global_user_name = username
    login_process = Popen(f"{sys.executable} email_login.py", stdout=PIPE, stdin=PIPE, shell=True, preexec_fn=os.setsid)
    login_process.stdout.readline().decode("utf-8")
    login_process.stdin.write(f"{username}\n".encode("utf-8"))
    login_process.stdin.flush()
    login_process.stdout.readline().decode("utf-8")
    login_process.stdin.write(f"{password}\n".encode("utf-8"))
    login_process.stdin.flush()
    info = login_process.stdout.readline().decode("utf-8")

    if "错误" in info:
        return info
    else:
        return "请查看邮箱验证码并输入"


def email_login_stage2(msg_code):
    global login_process
    login_process.stdin.write(f"{msg_code}\n".encode("utf-8"))
    login_process.stdin.flush()
    info = login_process.stdout.read().decode("utf-8")
    if "成功" in info:
        sid = re.search(r'Coremail.sid=(\w+)', info).group(1)
        coremail = re.search(r'Coremail=(\w+)', info).group(1)
        logger.info(f"Coremail.sid={sid}; Coremail={coremail};")
        shared.sid = sid
        requests.utils.add_dict_to_cookiejar(shared.cookies, {"Coremail.sid": sid})
        requests.utils.add_dict_to_cookiejar(shared.cookies, {"Coremail": coremail})
        get_email_list()
        total_size = sum([item['size'] for item in global_email_list]) / 1024 / 1024
        info = f"成功, 你有{len(global_email_list)}封邮件等待下载，共{total_size:.2f}MB"
    return info
            

def replace_date_format(text):
    pattern = r'new Date\((\d+),(\d+),(\d+),(\d+),(\d+),(\d+)\)'

    def repl(match):
        year, month, day, hour, minute, second = match.groups()
        month = str(int(month) + 1).zfill(2)
        day = str(int(day)).zfill(2)
        hour = str(int(hour)).zfill(2)
        minute = str(int(minute)).zfill(2)
        second = str(int(second)).zfill(2)
        return f"'{year}-{month}-{day} {hour}:{minute}:{second}'"

    return re.sub(pattern, repl, text)

def load_to_dict(json_string):
    json_string = replace_date_format(json_string)
    json_string = json_string\
                    .replace(":true", ":True")\
                    .replace(":false", ":False")\
                    .replace(":null", ":None")
    return ast.literal_eval(json_string)
    

def get_email_list():
    global global_email_list, global_user_name
    r = requests.post(list_url.format(sid=shared.sid, page_num=1), 
                      cookies=shared.cookies)
    if r.status_code != 200:
        logger.error("获取邮件列表失败")
        logger.error(r.text)
        global_email_list.clear()
        return "获取失败，请登录"
    global_email_list = r.json()["var"]
    total_size = sum([item['size'] for item in global_email_list]) / 1024 / 1024
    info = f"成功, 你有{len(global_email_list)}封邮件等待下载，共{total_size:.2f}MB"
    return info
    

async def adownload_one(email_info, save_dir, session: ClientSession, semaphore):
    mid = email_info["id"]
    async with session.get(download_url.format(sid=shared.sid, mid=mid)) as r, semaphore:
        if r.status == 200:
            file_path = os.path.join(save_dir, f"{email_info['subject'].replace('/', '_')}+{mid}.eml")
            logger.info(f"download {file_path}")
            f = await aiofiles.open(file_path, mode='wb')
            await f.write(await r.read())
            await f.close()
            logger.info(f"download {file_path} DONE")
            
def download_one(email_info, save_dir):
    mid = email_info["id"]
    r = requests.get(download_url.format(sid=shared.sid, mid=mid), 
                     cookies=shared.cookies)
    if r.status_code == 200:
        file_path = os.path.join(save_dir, f"{email_info['subject'].replace('/', '_')}+{mid}.eml")
        logger.info(f"download {file_path}")
        with open(file_path, "wb") as f:
            f.write(r.content)
        logger.info(f"download {file_path} DONE")
    else:
        logger.error(f"download {file_path} failed")
            
        
async def adownload_all(save_dir):
    async with ClientSession(cookies=shared.cookies) as session:
        tasks = []
        # 限制并发量
        semaphore = asyncio.Semaphore(shared.MAX_DOWNLOAD_TASKS)
        for email_info in global_email_list:
            task = asyncio.ensure_future(
                adownload_one(email_info, save_dir, session, semaphore)
            )
            tasks.append(task)
        await asyncio.gather(*tasks)     

def download_all(save_dir):
    for email_info in global_email_list:
        download_one(email_info, save_dir)

def download_all_click(save_dir):
    if not os.path.exists(save_dir) or os.path.isfile(save_dir):
        return "文件夹路径错误"
    # dump meta data
    with open(os.path.join(save_dir, "email_list.json"), "w") as f:
        json.dump(global_email_list, f, indent=4, ensure_ascii=False)
    st = time.time()
    if shared.MAIL_USE_ASYNC:
        loop = asyncio.new_event_loop()
        loop.run_until_complete(adownload_all(save_dir))
        ed = time.time()
        loop.close()
    else:
        download_all(save_dir)
        ed = time.time()
    logger.info(f"down load email time: {ed - st:.2f}")
    return f"down load email time: {ed - st:.2f}"
    

def tab_load():
    print("loading email tab")
    get_email_list()
    return f""



def get_email_tab():
    with gr.TabItem("清华邮箱") as tab:
        info = gr.Label(label="output box")
        explain = gr.Markdown(
"""## 提供邮箱迁移备份功能, 下载后的文件以eml文件格式保存, 包含附件,可以用飞书打开
- 验证码只能输入一次，第一次失败请重新登录
- 可能会出现网络问题中断下载，保险起见请全部重新下载
""")
        with gr.Row():
            username = gr.Textbox(lines=1, label="用户名")
            password = gr.Textbox(lines=1, label="密码", type="password")
            login_btn = gr.Button("登录")
            msg_code = gr.Textbox(lines=1, label="验证码")
            msg_code_verify_btn = gr.Button("验证码验证")
            
        path = gr.Textbox(lines=1, label="文件路径")
        download_all_btn = gr.Button("下载所有邮件")
    
    login_btn.click(fn=email_login_stage1,
                    inputs=[username, password],
                    outputs=[info])
    
    msg_code_verify_btn.click(fn=email_login_stage2,
                              inputs=[msg_code],
                              outputs=[info])

    # tab.select(fn=tab_load, outputs=[info])
    download_all_btn.click(fn=download_all_click,
                           inputs=[path],
                           outputs=[info])
    
    return tab