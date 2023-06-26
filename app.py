import gradio as gr
import requests
import time
import html
import os
from tqdm import tqdm
import logging

logging.basicConfig(filename="dowload.log",
                    filemode='a')
logger = logging.getLogger(__file__)
logger.setLevel("INFO")

sessionid = ""
global_repos = []
global_name_to_repos = {}
global_download_base = ""



def download_file(url, filename):
    global sessionid
    response = requests.get(url, stream=True, cookies={"sessionid":sessionid})
    total = int(response.headers.get('content-length', 0))
    
    with open(filename, "wb") as f, tqdm(desc=f"downloading {filename}", total=total, unit="iB", unit_scale=True, unit_divisor=1024) as bar:
        for data in response.iter_content(chunk_size=1024):
            size = f.write(data)
            bar.update(size)
    


def get_dir_list(repo_id, relative_path):
    global sessionid
    relative_path = relative_path.replace("/", "%2F")
    response = requests.get(f"https://cloud.tsinghua.edu.cn/api/v2.1/repos/{repo_id}/dir/?p={relative_path}&with_thumbnail=true",  cookies={"sessionid":sessionid}).json()
    return response.get("dirent_list", None)
    
    
    
    
    
def test_sessionid(input_sessionid, progress=gr.Progress(track_tqdm=True)):
    # test_sessionid and set list
    global sessionid
    sessionid = input_sessionid
    response = requests.get("https://cloud.tsinghua.edu.cn/api/v2.1/repos/?type=mine", cookies={
        "sessionid":sessionid
    })
    dic = response.json()
    if response.status_code != 200:
        return "非法sesionid", [], ""
    elif dic.get("repos", None) is None:
        return "获取仓库列表错误", [], ""
    else:
        global global_repos
        global_repos = dic["repos"]
        gr.update()
        
        # get file list for every repo
        for i, repo in progress.tqdm(zip(range(len(global_repos)), global_repos)):
            response = requests.get(f'https://cloud.tsinghua.edu.cn/api/v2.1/repos/{repo["repo_id"]}/', cookies={"sessionid":sessionid})
            js = response.json()
            global_repos[i]["total_size"] = js["size"] / (1024*1024)
            global_repos[i]["file_count"] = js["file_count"]
            global_name_to_repos[repo["repo_name"]] = global_repos[i]
            
        select_string = ""
        for i in global_repos:
            select_string += f'{i["repo_name"]}\n'
        
        return ("sessionid检验成功", 
                [ [ i["repo_name"], i["file_count"], f'{i["total_size"]:.2f}MB'] for i in global_repos], 
                select_string
                )



with gr.Blocks() as demo:
    with gr.Row():
        with gr.Column():
            sessionid = gr.Textbox(label="sessionid", placeholder="输入请求中的sessionid, 以此为应用提供访问权限")
            output = gr.Label(label="Output Box")
            greet_btn = gr.Button("测试token")


        with gr.Column():
            path = gr.Textbox(label="下载路径", placeholder="提供下载路径")
            dowload_btn = gr.Button("下载全部")

            
    
    
    with gr.Tabs(elem_id="repo_list") as tabs:
        with gr.TabItem("repos"):
            headers = ["仓库名称", "文件数量", "总大小"]
            ls = gr.List(col_count=len(headers), headers=headers)
            select_string = gr.Textbox("每行选择一个仓库进行下载")
            subset_down_load_btn = gr.Button("选择下载")
            greet_btn.click(fn=test_sessionid, inputs=[sessionid], outputs=[output, ls, select_string], api_name="test")
            
            
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