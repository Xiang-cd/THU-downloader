##清华云盘相关的接口

import requests
import gradio as gr
import os
import json
import time
from tqdm import tqdm
import logging
import shared
import utils
import functools
import asyncio
import aiohttp
import aiofiles
from aiohttp import ClientSession
import nest_asyncio
nest_asyncio.apply()

logging.basicConfig(filename="dowload.log",
                    filemode='a')
logger = logging.getLogger(__file__)
logger.setLevel("INFO")


global_repos = []
global_name_to_repos = {}
global_download_base = ""
global_list_data = []

use_coroutine = True

def get_repos(progress=gr.Progress(track_tqdm=True)):
    # 刚进入tab时加载所有的仓库
    global global_repos
    response = requests.get("https://cloud.tsinghua.edu.cn/api/v2.1/repos/?type=mine", cookies=shared.cookie)
    if response.status_code != 200:
        return "请先登录", []
    try:
        dic = response.json()
    except:
        logger.error(response.text)
        return "获取目录失败", []
    
    global_repos = dic["repos"]
    
    
    async def get_repos_info():
        data_ls = []
        async with ClientSession(cookies=shared.cookie) as session:
            for index, repo in enumerate(global_repos):
                async with session.get(f'https://cloud.tsinghua.edu.cn/api/v2.1/repos/{repo["repo_id"]}/') as response:
                    if response.status == 200:
                        data = await response.json()
                        data_ls.append((data, index))
                    else:
                        print(f"fail for {repo}")
        
        return data_ls

    try:
        loop = asyncio.get_event_loop()
    except:
        loop = asyncio.new_event_loop()
    st = time.time()
    ret = loop.run_until_complete(get_repos_info())
    ed = time.time()
    loop.close()
    logger.info(f"get info list time: {ed - st}")
    
    
    global global_list_data
    for js, index in ret:
        global_repos[index]["total_size"] = js["size"] / (1024*1024)
        global_repos[index]["file_count"] = js["file_count"]
        global_name_to_repos[global_repos[index]["repo_name"]] = global_repos[index]
        global_list_data.append([global_repos[index]["repo_name"], js["file_count"], f"""{global_repos[index]["total_size"]:.2f}MB"""])

    code = utils.get_select_table(headers=["仓库名称", "文件数量", "总大小"],
                                  data=global_list_data,
                                  table_mark="select_table",
                                  selected_index=[])
    
    return "加载成功", code


def download_file(url, filename):
    response = requests.get(url, stream=True, cookies=shared.cookie)
    total = int(response.headers.get('content-length', 0))
    
    with open(filename, "wb") as f:
        for data in response.iter_content(chunk_size=1024*20):
            size = f.write(data)
    

def get_dir_list(repo_id, relative_path):
    relative_path = relative_path.replace("/", "%2F")
    response = requests.get(f"https://cloud.tsinghua.edu.cn/api/v2.1/repos/{repo_id}/dir/?p={relative_path}&with_thumbnail=true",  cookies=shared.cookie).json()
    return response.get("dirent_list", None)


def dowload_dir(repo_name, relative_dir_path):
    logger.debug(f"cur relative_dir_path {relative_dir_path}")
    global global_download_base, global_name_to_repos
    repo_id = global_name_to_repos[repo_name]["repo_id"]
    
    contents = get_dir_list(repo_id, relative_dir_path)
    cur_os_dir = os.path.join(global_download_base, repo_name, relative_dir_path)
    logger.info(f"making dir cur os dir {cur_os_dir}")
    os.makedirs(cur_os_dir, exist_ok=True)
    
    
    for content in tqdm(contents, desc="dir progress"):
        p_dir = content["parent_dir"][1:] if content["parent_dir"].startswith("/") else content["parent_dir"]
        content_relative_path = os.path.join(p_dir, content["name"])
        if content["type"] == "file":
            file_path = os.path.join(cur_os_dir, content["name"])
            logger.info(f"dowloading {file_path}")
            download_file(f'https://cloud.tsinghua.edu.cn/lib/{repo_id}/file/{content_relative_path}?dl=1', file_path)

        elif content["type"] == "dir":
            dowload_dir(repo_name, content_relative_path)


def download_repo(name, path, progress=gr.Progress()):
    global global_name_to_repos
    logger.info(f"downloading {name}")
    repo_id = global_name_to_repos[name]["repo_id"]

    contents = get_dir_list(repo_id, "/")
    repo_dir = os.path.join(path, name)
    logger.info(f"making dir {repo_dir}")
    os.makedirs(repo_dir, exist_ok=True)
    

    for content in progress.tqdm(contents, desc="inner repo progress"):
        if content["type"] == "file":
            file_path = os.path.join(repo_dir, content["name"])
            logger.info(f"dowloading {file_path}")
            download_file(f'https://cloud.tsinghua.edu.cn/lib/{repo_id}/file/{content["name"]}?dl=1', file_path)

        elif content["type"] == "dir":
            dowload_dir(name, f'{content["name"]}')
            
            


async def adownload_file(url, filename, session):
    print(filename)
    async with session.get(url) as resp:
        if resp.status == 200:
            f = await aiofiles.open(filename, mode='wb')
            await f.write(await resp.read())
            await f.close()
            
            
async def aget_dir_list(repo_id, relative_path, session):
    relative_path = relative_path.replace("/", "%2F")
    async with session.get(f"https://cloud.tsinghua.edu.cn/api/v2.1/repos/{repo_id}/dir/?p={relative_path}&with_thumbnail=true") as resp:
        res = await resp.json()
        return res.get("dirent_list", None)

async def adowload_dir(repo_name, relative_dir_path, session):
    logger.debug(f"cur relative_dir_path {relative_dir_path}")
    global global_download_base, global_name_to_repos
    repo_id = global_name_to_repos[repo_name]["repo_id"]
    
    contents = await aget_dir_list(repo_id, relative_dir_path, session)
    cur_os_dir = os.path.join(global_download_base, repo_name, relative_dir_path)
    logger.info(f"making dir cur os dir {cur_os_dir}")
    os.makedirs(cur_os_dir, exist_ok=True)
    
    
    for content in tqdm(contents, desc="dir progress"):
        p_dir = content["parent_dir"][1:] if content["parent_dir"].startswith("/") else content["parent_dir"]
        content_relative_path = os.path.join(p_dir, content["name"])
        if content["type"] == "file":
            file_path = os.path.join(cur_os_dir, content["name"])
            logger.info(f"dowloading {file_path}")
            await adownload_file(f'https://cloud.tsinghua.edu.cn/lib/{repo_id}/file/{content_relative_path}?dl=1', file_path, session=session)

        elif content["type"] == "dir":
            await adowload_dir(repo_name, content_relative_path, session=session)


async def adownload_repo(name, path, progress=gr.Progress()):
    global global_name_to_repos
    logger.info(f"downloading {name}")
    repo_id = global_name_to_repos[name]["repo_id"]

    async with ClientSession(cookies=shared.cookie) as session:
        contents = await aget_dir_list(repo_id, "/", session)
        repo_dir = os.path.join(path, name)
        logger.info(f"making dir {repo_dir}")
        os.makedirs(repo_dir, exist_ok=True)
        
        for content in progress.tqdm(contents, desc="inner repo progress"):
            if content["type"] == "file":
                file_path = os.path.join(repo_dir, content["name"])
                logger.info(f"dowloading {file_path}")
                await adownload_file(f'https://cloud.tsinghua.edu.cn/lib/{repo_id}/file/{content["name"]}?dl=1', file_path, session=session)

            elif content["type"] == "dir":
                await adowload_dir(name, f'{content["name"]}', session=session)


def download_subset(selected_index, path, progress=gr.Progress()):
    logger.debug(selected_index, type(selected_index))
    selected_index = json.loads(selected_index)
    selected_index = [int(i) for i in selected_index]
    global global_repos, global_download_base
    global_download_base = path

    repo_names = [global_repos[i]["repo_name"] for i in selected_index]

    logger.info("download subset")
    download_start = time.time()
    if os.path.exists(path) and os.path.isdir(path):
        for repo in progress.tqdm(repo_names, desc="repo download progress"):
            if use_coroutine:
                try:
                    loop = asyncio.get_event_loop()
                except:
                    loop = asyncio.new_event_loop()
                st = time.time()
                loop.run_until_complete(adownload_repo(repo, path, progress))
                ed = time.time()
                loop.close()
            else:
                download_repo(repo, path, progress)
        download_end = time.time()
        logger.info(f"download subset using time {download_end - download_start:.2f}s")
        return f"ok, using time {download_end - download_start:.2f}s"
    else:
        return "路径不存在或者路径不是文件夹"

def select_all_click(all):
    global global_list_data
    
    if all:
        code = utils.get_select_table(headers=["仓库名称", "文件数量", "总大小"],
                                  data=global_list_data,
                                  table_mark="select_table",
                                  selected_index=list(range(len(global_list_data))))
    else:
        code = utils.get_select_table(headers=["仓库名称", "文件数量", "总大小"],
                                  data=global_list_data,
                                  table_mark="select_table",
                                  selected_index=[])
    return code
    
    

def get_cloud_tab():
    with gr.TabItem("清华云盘") as cloud_tab:
        cloud_info = gr.Label(label="Output Box")
        with gr.Row():
            with gr.Column():
                path = gr.Textbox(label="下载路径", placeholder="提供下载路径")
                with gr.Row():
                    select_all = gr.Button("全选")
                    unselect_all = gr.Button("取消全选")
                
        select_table = gr.HTML()
        subset_down_load_btn = gr.Button("选择下载")
        
        selected_list = gr.Text(elem_id="extensions_disabled_list", visible=False)
        cloud_tab.select(fn=get_repos, inputs=[], outputs=[cloud_info, select_table])

        select_all.click(fn=functools.partial(select_all_click, True),
                         inputs=[],
                         outputs=[select_table])
        unselect_all.click(fn=functools.partial(select_all_click, False),
                           inputs=[],
                           outputs=[select_table])
        subset_down_load_btn.click(fn=download_subset, 
                                   inputs=[selected_list, path], 
                                   outputs=[cloud_info],
                                   _js="selected_repo")
    
    return cloud_tab
            