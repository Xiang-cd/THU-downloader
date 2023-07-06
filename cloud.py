##清华云盘相关的接口
import requests
import gradio as gr
import os
import json
from tqdm import tqdm
import logging
import shared
import utils

logging.basicConfig(filename="dowload.log",
                    filemode='a')
logger = logging.getLogger(__file__)
logger.setLevel("INFO")


global_repos = []
global_name_to_repos = {}
global_download_base = ""



def get_repos(progress=gr.Progress(track_tqdm=True)):
    # 刚进入tab时加载所有的仓库
    global global_repos
    response = requests.get("https://cloud.tsinghua.edu.cn/api/v2.1/repos/?type=mine", cookies=shared.cookie)
    if response.status_code != 200:
        return "请先登录", []
    dic = response.json()
    global_repos = dic["repos"]
    
    list_data = []
    # get file list for every repo
    for i, repo in progress.tqdm(zip(range(len(global_repos)), global_repos)):
        response = requests.get(f'https://cloud.tsinghua.edu.cn/api/v2.1/repos/{repo["repo_id"]}/', cookies=shared.cookie)
        js = response.json()
        global_repos[i]["total_size"] = js["size"] / (1024*1024)
        global_repos[i]["file_count"] = js["file_count"]
        global_name_to_repos[repo["repo_name"]] = global_repos[i]
        list_data.append([repo["repo_name"], js["file_count"], f"""{global_repos[i]["total_size"]:.2f}MB"""])
    
    table_headers = ["仓库名称", "文件数量", "总大小"]

    code = utils.get_select_table(headers=table_headers,
                                  data=list_data,
                                  table_mark="select_table",
                                  selected_index=[])
    
    return "加载成功", code


def download_file(url, filename):
    global cookie
    response = requests.get(url, stream=True, cookies=shared.cookie)
    total = int(response.headers.get('content-length', 0))
    
    with open(filename, "wb") as f, tqdm(desc=f"downloading {filename}", total=total, unit="iB", unit_scale=True, unit_divisor=1024) as bar:
        for data in response.iter_content(chunk_size=1024):
            size = f.write(data)
            bar.update(size)
    

def get_dir_list(repo_id, relative_path):
    relative_path = relative_path.replace("/", "%2F")
    response = requests.get(f"https://cloud.tsinghua.edu.cn/api/v2.1/repos/{repo_id}/dir/?p={relative_path}&with_thumbnail=true",  cookies=shared.cookie).json()
    return response.get("dirent_list", None)


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


def download_subset(selected_index, path, progress=gr.Progress(track_tqdm=True)):
    print(selected_index, type(selected_index))
    selected_index = json.loads(selected_index)
    selected_index = [int(i) for i in selected_index]
    global global_repos, global_download_base
    global_download_base = path

    repo_names = [global_repos[i]["repo_name"] for i in selected_index]

    logger.info("download subset")
    if os.path.exists(path) and os.path.isdir(path):
        for repo in tqdm(repo_names, desc="repo_progress"):
            download_repo(repo, path, progress)
        return "ok"
    else:
        return "路径不存在或者路径不是文件夹"


def download_all(path, progress=gr.Progress(track_tqdm=True)):
    global global_repos, global_download_base
    global_download_base = path
    logger.info("download all")
    
    if os.path.exists(path) and os.path.isdir(path):
        for repo in tqdm(global_repos, desc="repo_progress"):
            download_repo(repo["repo_name"], path, progress)
        return "ok"
    else:
        return "路径不存在或者路径不是文件夹"
    

def get_cloud_tab():
    with gr.TabItem("清华云盘") as cloud_tab:
        cloud_info = gr.Label(label="Output Box")
        with gr.Row():
            with gr.Column():
                path = gr.Textbox(label="下载路径", placeholder="提供下载路径")
                dowload_btn = gr.Button("下载全部")
                
        select_table = gr.HTML(utils.get_select_table(["name", "size"], [["a", "12"], ["b", "22"]], "ok", [0]))
        subset_down_load_btn = gr.Button("选择下载")
        
        selected_list = gr.Text(elem_id="extensions_disabled_list", visible=False)
        cloud_tab.select(fn=get_repos, inputs=[], outputs=[cloud_info, select_table])

        dowload_btn.click(fn=download_all, inputs=[path], outputs=[cloud_info])
        subset_down_load_btn.click(fn=download_subset, 
                                   inputs=[selected_list, path], 
                                   outputs=[cloud_info],
                                   _js="selected_repo")
    
    return cloud_tab
            