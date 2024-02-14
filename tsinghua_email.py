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
                    filemode='a')
logger = logging.getLogger(Path(__file__).name)
logger.setLevel(shared.LOG_LEVEL)

global_email_list = []
list_url = "https://mails.tsinghua.edu.cn/coremail/XT3/mbox/getListDatas.jsp?sid={sid}&fid=1&nav_type=system&inbox=true&page_no={page_num}"
email_url = "https://mails.tsinghua.edu.cn/coremail/XT3/mbox/viewMailHTML.jsp?mid={mid}&partId=0&isSearch=&priority=&supportSMIME=&striptTrs=true&mboxa=&sandbox=1"
download_url = "https://mails.tsinghua.edu.cn/coremail/XT3/mbox/allDownload.jsp?sid={sid}&mid={mid}&mboxa="

login_process = None


def email_login_stage1(username, password):
    global login_process
    if login_process is not None:
        try:
            os.killpg(os.getpgid(login_process.pid), signal.SIGTERM)
        except:
            pass
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
        return "请查看邮箱密码"


def email_login_stage2(msg_code):
    global login_process
    login_process.stdin.write(f"{msg_code}\n".encode("utf-8"))
    login_process.stdin.flush()
    info, sid = login_process.stdout.readline().decode("utf-8").split()
    if "成功" in info:
        shared.sid = sid
        requests.utils.add_dict_to_cookiejar(shared.cookies, {"Coremail.sid":shared.sid})
        loop = asyncio.new_event_loop()
        st = time.time()
        loop.run_until_complete(get_email_list())
        ed = time.time()
        loop.close()
        logger.info(f"get info list time: {ed - st:.2f}, len(global_email_list)={len(global_email_list)}") 
        info += f"加载耗时: {ed - st:.2f}, 你有{len(global_email_list)}封邮件等待下载"

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
    

    

async def get_email_list():
    global global_email_list
    r = requests.post(list_url.format(sid=shared.sid, page_num=1), 
                      cookies=shared.cookies)
    if r.status_code != 200:
        logger.error("获取邮件列表失败")
        logger.error(r.text)
        return []
    dic_data = load_to_dict(r.text)
    totol_mail_num = dic_data["total"]
    assert dic_data["offset"] == 0
    global_email_list += dic_data["msgList"]
    

    # 默认每次返回200个邮件信息
    async def get_page(page_num, session: ClientSession):
        global global_email_list
        async with session.post(list_url.format(sid=shared.sid, page_num=page_num),
                          cookies=shared.cookies) as r:
            if r.status != 200:
                logger.error(f"获取邮件列表失败: page_num={page_num}")
                return
            dic_data = load_to_dict(await r.text())
            assert dic_data["offset"] == (page_num-1) * 200
            global_email_list += dic_data["msgList"]
    
    async with ClientSession(cookies=shared.cookies) as session:
        tasks = []
        for page_num in range(2, (totol_mail_num-1) // 200 + 2):
            task = asyncio.ensure_future(
                get_page(page_num, session)
            )
            tasks.append(task)
        await asyncio.gather(*tasks)
        
    assert totol_mail_num == len(global_email_list)

async def adownload_one(email_info, save_dir, session: ClientSession):
    mid = email_info["item"]["id"]
    receivedDate = email_info["item"]["receivedDate"]
    async with session.get(download_url.format(sid=shared.sid, mid=mid)) as r:
        if r.status == 200:
            file_path = os.path.join(save_dir, f"{receivedDate}+{mid}.zip")
            logger.info(f"正在下载{file_path}")
            f = await aiofiles.open(file_path, mode='wb')
            logger.info(f"download {file_path}")
            await f.write(await r.read())
            await f.close()
            # 先下载到zip, 再解压才能得到正确的邮件内容(图片,附件能够正常打开)
            # 丑陋就丑陋一点吧
            logger.info(f"{file_path} 下载完成")
            f = zipfile.ZipFile(file_path,'r')
            for name in f.namelist():
                extract_path = Path(f.extract(name, save_dir))
                new_name = name.encode("cp437").decode("gb18030")
                extract_path.rename(extract_path.with_name(new_name))
                logger.info(f"{file_path} 解压完成")
            f.close()
            await aiofiles.os.remove(file_path)
            logger.info(f"{file_path} 删除完成")
            
        
async def download_all(save_dir):
    async with ClientSession(cookies=shared.cookies) as session:
        tasks = []
        for email_info in global_email_list:
            task = asyncio.ensure_future(
                adownload_one(email_info, save_dir, session)
            )
            tasks.append(task)
        await asyncio.gather(*tasks)     

def download_all_click(save_dir):
    if not os.path.exists(save_dir) or os.path.isfile(save_dir):
        return "文件夹路径错误"
    
    loop = asyncio.new_event_loop()
    st = time.time()
    loop.run_until_complete(download_all(save_dir))
    ed = time.time()
    loop.close()
    logger.info(f"down load email time: {ed - st:.2f}")
    return f"down load email time: {ed - st:.2f}"
    

def tab_load():
    global global_email_list
    global_email_list.clear()
    return f""



def get_email_tab():
    with gr.TabItem("清华邮箱") as tab:
        info = gr.Label(label="output box")
        explain = gr.Markdown("## 提供邮箱迁移备份功能, 下载后的文件以eml文件格式保存, 包含附件,可以用飞书打开")
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

    tab.select(fn=tab_load, outputs=[info])
    download_all_btn.click(fn=download_all_click,
                           inputs=[path],
                           outputs=[info])
    
    return tab