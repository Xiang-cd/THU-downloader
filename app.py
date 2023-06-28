import gradio as gr
import requests
import time
import html
import os
from tqdm import tqdm
import logging
import os, html, urllib
from tqdm import tqdm
import urllib.request, http.cookiejar
import re
import ssl
import requests

ssl._create_default_https_context = ssl._create_unverified_context

user_agent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.130 Safari/537.36'
headers = {'User-Agent': user_agent, 'Connection': 'keep-alive'}
cookie = http.cookiejar.MozillaCookieJar()
handler = urllib.request.HTTPCookieProcessor(cookie)
opener = urllib.request.build_opener(handler)
urllib.request.install_opener(opener)

logging.basicConfig(filename="dowload.log",
                    filemode='a')
logger = logging.getLogger(__file__)
logger.setLevel("INFO")

sessionid = ""
global_repos = []
global_name_to_repos = {}
global_download_base = ""


def open_page(uri, values={}):
    global headers
    post_data = urllib.parse.urlencode(values).encode() if values else None
    request = urllib.request.Request(uri, post_data, headers)
    try:
        response = opener.open(request)
        return response
    except urllib.error.URLError as e:
        print(uri, e.code, ':', e.reason)


def get_page(uri, values={}):
    data = open_page(uri, values)
    if data:
        return data.read().decode()


def login(username, password, progress=gr.Progress(track_tqdm=True)):
    global global_repos, cookie
    login_uri = 'https://id.tsinghua.edu.cn/do/off/ui/auth/login/post/167ed2c25d7f176c20c79e341e2ccdf0/0?/login.do'
    values = {'i_user': username, 'i_pass': password, 'atOnce': 'true'}
    info = get_page(login_uri, values)
    
    ticket = re.findall('ticket=(.+?)"', info)
    successful = len(ticket) > 0
    if successful:
        logger.info(f"{username} login successs")
        open_page(f"https://cloud.tsinghua.edu.cn/tsinghua-auth/callback/?ticket={ticket[0]}")
        response = requests.get("https://cloud.tsinghua.edu.cn/api/v2.1/repos/?type=mine", cookies=cookie)
        dic = response.json()
        global_repos = dic["repos"]
        
        # get file list for every repo
        for i, repo in progress.tqdm(zip(range(len(global_repos)), global_repos)):
            response = requests.get(f'https://cloud.tsinghua.edu.cn/api/v2.1/repos/{repo["repo_id"]}/', cookies=cookie)
            js = response.json()
            global_repos[i]["total_size"] = js["size"] / (1024*1024)
            global_repos[i]["file_count"] = js["file_count"]
            global_name_to_repos[repo["repo_name"]] = global_repos[i]
            
        select_string = ""
        for i in global_repos:
            select_string += f'{i["repo_name"]}\n'
        
        gr.update()
        return ("登录成功", 
                [ [ i["repo_name"], i["file_count"], f'{i["total_size"]:.2f}MB'] for i in global_repos], 
                select_string)
    else:
        return "登录失败", [], ""


def download_file(url, filename):
    global sessionid
    response = requests.get(url, stream=True, cookies=cookie)
    total = int(response.headers.get('content-length', 0))
    
    with open(filename, "wb") as f, tqdm(desc=f"downloading {filename}", total=total, unit="iB", unit_scale=True, unit_divisor=1024) as bar:
        for data in response.iter_content(chunk_size=1024):
            size = f.write(data)
            bar.update(size)
    


def get_dir_list(repo_id, relative_path):
    global sessionid
    relative_path = relative_path.replace("/", "%2F")
    response = requests.get(f"https://cloud.tsinghua.edu.cn/api/v2.1/repos/{repo_id}/dir/?p={relative_path}&with_thumbnail=true",  cookies=cookie).json()
    return response.get("dirent_list", None)
    
    
    



with gr.Blocks() as demo:
    output = gr.Label(label="Output Box")
    with gr.Row():
        with gr.Column():
            path = gr.Textbox(label="下载路径", placeholder="提供下载路径")
            dowload_btn = gr.Button("下载全部")
            
        with gr.Column():
            username = gr.Textbox(label="username", placeholder="输入用户名")
            password = gr.Textbox(label="password", placeholder="输入密码", type="password")
            login_btn = gr.Button("登录")
            
    
    with gr.Tabs(elem_id="repo_list") as tabs:
        with gr.TabItem("repos"):
            table_headers = ["仓库名称", "文件数量", "总大小"]
            ls = gr.List(col_count=len(table_headers), headers=table_headers)
            select_string = gr.Textbox("每行选择一个仓库进行下载")
            subset_down_load_btn = gr.Button("选择下载")
            login_btn.click(fn=login, inputs=[username, password], outputs=[output, ls, select_string])
            
            
            def dowload_dir(repo_name, relative_dir_path):
                global global_download_base, global_name_to_repos
                repo_id = global_name_to_repos[repo_name]["repo_id"]
                
                contents = get_dir_list(repo_id, relative_dir_path)
                cur_os_dir = os.path.join(global_download_base, repo_name, relative_dir_path)
                logger.info(f"making dir cur os dir {cur_os_dir}")
                os.makedirs(cur_os_dir, exist_ok=True)
                
                
                for content in tqdm(contents, desc="inner progress"):
                    content_relative_path = os.path.join(content["parent_dir"], content["name"])
                    if content["type"] == "file":
                        file_path = os.path.join(cur_os_dir, content["name"])
                        logger.info(f"dowloading {file_path}")
                        download_file(f'https://cloud.tsinghua.edu.cn/lib/{repo_id}/file/{content_relative_path}?dl=1', file_path)

                    elif content["type"] == "dir":
                        dowload_dir(repo_name, content_relative_path)

        

            def download_repo(name, path, progress=gr.Progress(track_tqdm=True)):
                global global_name_to_repos
                logger.info(f"downloading {name}")
                repo_id = global_name_to_repos[name]["repo_id"]

                contents = get_dir_list(repo_id, "/")
                repo_dir = os.path.join(path, name)
                logger.info(f"making dir {repo_dir}")
                os.makedirs(repo_dir, exist_ok=True)
                

                for content in tqdm(contents, desc="inner progress"):
                    if content["type"] == "file":
                        file_path = os.path.join(repo_dir, content["name"])
                        logger.info(f"dowloading {file_path}")
                        download_file(f'https://cloud.tsinghua.edu.cn/lib/{repo_id}/file/{content["name"]}?dl=1', file_path)

                    elif content["type"] == "dir":
                        dowload_dir(name, f'{content["name"]}')

            
        
            def download_subset(path, select_string, progress=gr.Progress(track_tqdm=True)):
                global sessionid, global_repos, global_name_to_repos, global_download_base
                global_download_base = path
                repo_names = select_string.strip().split("\n")
                repo_names = [i for i in repo_names if i != ""]
                for repo in repo_names:
                    if repo not in global_name_to_repos.keys():
                        logger.error(repo)
                        logger.error(global_name_to_repos.keys())
                        return "选择的仓库不存在"
            
                
                logger.info("download subset")
                if os.path.exists(path) and os.path.isdir(path):
                    for repo in tqdm(repo_names, desc="repo_progress"):
                        download_repo(repo, path, progress)
                    return "ok"
                else:
                    return "路径不存在或者路径不是文件夹"

                    
            def download_all(path, progress=gr.Progress(track_tqdm=True)):
                global sessionid, global_repos, global_download_base
                global_download_base = path
                logger.info("download all")
                
                if os.path.exists(path) and os.path.isdir(path):
                    for repo in tqdm(global_repos, desc="repo_progress"):
                        download_repo(repo["repo_name"], path, progress)
                    return "ok"
                else:
                    return "路径不存在或者路径不是文件夹"
            
            dowload_btn.click(fn=download_all, inputs=[path], outputs=output)
            subset_down_load_btn.click(fn=download_subset, inputs=[path, select_string], outputs=output)
            
    

demo.queue().launch()