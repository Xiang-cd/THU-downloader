# 分享链接下载相关接口
import gradio as gr
import re
from urllib.parse import quote
import requests
import utils
import os
import json
import time
import logging
import shared
import functools

logging.basicConfig(filename="dowload.log",
                    filemode='a')
logger = logging.getLogger(__file__)
logger.setLevel(shared.LOG_LEVEL)

download_url = 'https://cloud.tsinghua.edu.cn/d/{}/files/?p={}&dl=1'
rdownload_url = "https://cloud.tsinghua.edu.cn/d/{}/files/?p={}"
dirent_url = 'https://cloud.tsinghua.edu.cn/api/v2.1/share-links/{}/dirents/?path={}'
content_list = []
share_key = ""
can_download = True

use_coroutine = True

def get_share_key(share_link):
    key = re.findall(r"https://cloud\.tsinghua\.edu\.cn/d/(\w+)", share_link)
    return key[0] if key else None


def data_ls_from_content_list():
    global content_list
    data_ls = []
    for d in content_list:
        if d["is_dir"]:
            data_ls.append([d["folder_name"], "文件夹", "文件夹", d["last_modified"]])
        else:
            data_ls.append([d["file_name"], 
                            f'{d["size"] / (1024 * 1024):.2f} MB',
                            "文件",
                            d["last_modified"]])
    return data_ls

def format_data_ls(data_ls, selected_index=[]):
    # return formated data ls to html code
    return utils.get_select_table(
            ["文件(文件夹)名称", "文件大小", "文件类型", "最近修改时间"],
            data_ls,
            "link_download",
            selected_index
        )

def select_all_click(all):
    global content_list
    data_ls = data_ls_from_content_list()
    return format_data_ls(data_ls, list(range(len(data_ls)))) if all \
            else format_data_ls(data_ls, [])


def parse_btn_click(share_link):
    code = ""
    global share_key, can_download
    share_key = get_share_key(share_link)
    if share_key is None:
        return "分享链接格式错误", code
    
    logger.debug(f"query url {dirent_url.format(share_key, quote('/'))}")
    r = requests.get(share_link)
    can_download = re.findall(r"canDownload: (.+?),", r.text)[0] == "true"
    
    r = requests.get(dirent_url.format(share_key, quote("/")))
    
    if r.status_code == 404:
        return "内容不存在，T^T，看看是不是链接输错了？", code
    if r.status_code == 500:
        return "清华网盘在摸鱼 (=´ω｀=)...过一段时间再试试吧", code
    global content_list
    content_list = r.json()["dirent_list"]
    logger.debug(f"content_list: {content_list}")

    data_ls = data_ls_from_content_list()
    code = format_data_ls(data_ls)
    info = f"解析成功, 可下载且预览" if can_download else f"解析成功, 仅预览"
    return info, code



def downlaod_file(d, save_path):
    global share_key, can_download
    file_path = os.path.join(save_path, d["file_name"])
    logger.info(f"downloading {file_path}")
    
    if can_download:
        url = download_url.format(share_key, quote(d["file_path"]))
        r = requests.get(url, stream=True)
    else:
        logger.warning(f"preview only shared link, try with rdownload_url")
        url = rdownload_url.format(share_key, quote(d["file_path"]))
        raw_res = requests.get(url) # page with the actual download link
        try:
            rawPath = re.findall(r"rawPath: \'(.+)\'", raw_res.text)[0].encode('utf-8').decode('unicode-escape')
        except:
            logger.error(f"rawPath not found in {raw_res.text}")
            return
        logger.debug(f"rawPath: {rawPath}")
        r = requests.get(rawPath, stream=True)
    
    
    with open(file_path, "wb") as f:
        for data in r.iter_content(chunk_size=1024*20):
            f.write(data)
    
    logger.info(f"download {file_path} success")

def downlaod_dir(d, save_path):
    cur_dir_path = os.path.join(save_path, d["folder_name"])
    logger.debug(f"当前写在信息：{d}")
    logger.debug(f"创建文件夹：{cur_dir_path}")
    os.makedirs(cur_dir_path, exist_ok=True)

    r = requests.get(dirent_url.format(share_key, quote(d["folder_path"])))

    if r.status_code != 200:
        if r.status_code == 404:
            logger.error(f"{d}, 404")
        if r.status_code == 500:
            logger.error(f"{d} 500")
        return
    else:
        local_content_list = r.json()["dirent_list"]
        for d in local_content_list:
            if d["is_dir"]:
                downlaod_dir(d, cur_dir_path)
            else:
                downlaod_file(d, cur_dir_path)


def download_btn_click(selected_index, save_path):
    global content_list
    save_path = save_path.strip()
    if not content_list:
        return "请先解析链接"
    if not save_path or not os.path.exists(save_path):
        return "请先输入保存路径or路径不存在"
    
    selected_index = json.loads(selected_index)
    selected_index = [int(i) for i in selected_index]
    logger.debug(f"{selected_index}, {save_path}")

    download_start = time.time()
    for i in selected_index:
        d = content_list[i]

        if d["is_dir"]:
            downlaod_dir(d, save_path)
        else:
            downlaod_file(d, save_path)

    download_end = time.time()
    logger.info(f"下载耗时：{download_end - download_start:.2f}s")

    return f"下载成功, 耗时：{download_end - download_start:.2f}s"



def get_link_download_tab():


    with gr.TabItem("分享链接下载") as tab:
        info = gr.Label(label="消息提示")

        share_link = gr.Textbox(label="分享链接", lines=1)
        save_path= gr.Textbox(label="保存路径", lines=1)
        with gr.Row():
            select_all = gr.Button("全选")
            unselect_all = gr.Button("取消全选")

        parse_btn = gr.Button("解析")
        link_content = gr.HTML(label="链接内容")
        download_btn = gr.Button("下载")
        
        select_all.click(
            fn=functools.partial(select_all_click, False),
            outputs=[link_content],
        )
        unselect_all.click(
            fn=functools.partial(select_all_click, False),
            outputs=[link_content],
        )

        parse_btn.click(fn=parse_btn_click,
                        inputs=[share_link],
                        outputs=[info, link_content])
        
        share_link.submit(fn=parse_btn_click,
                        inputs=[share_link],
                        outputs=[info, link_content])
        
        selected_list = gr.Text(visible=False)
        download_btn.click(fn=download_btn_click,
                           inputs=[selected_list, save_path],
                           outputs=[info],
                           _js="selected_link_download")
        

    return tab








