# 分享链接下载相关接口
import gradio as gr
import re
from urllib.parse import quote
import requests
import utils

download_url = 'https://cloud.tsinghua.edu.cn/d/{}/files/?p={}&dl=1'
dirent_url = 'https://cloud.tsinghua.edu.cn/api/v2.1/share-links/{}/dirents/?path={}'
content_list = []

def get_share_key(share_link):
    key = re.findall(r"https://cloud\.tsinghua\.edu\.cn/d/(\w+)", share_link)
    return key[0] if key else None




def parse_btn_click(share_link):
    code = ""
    share_key = get_share_key(share_link)
    if share_key is None:
        return "分享链接格式错误", code
    
    r = requests.get(dirent_url.format(share_key, quote("/")))
    
    if r.status_code == 404:
        return "内容不存在，T^T，看看是不是链接输错了？", code
    if r.status_code == 500:
        return "清华网盘在摸鱼 (=´ω｀=)...过一段时间再试试吧", code
    global content_list
    content_list = r.json()["dirent_list"]

    data_ls = []
    for d in content_list:
        if d["is_dir"]:
            data_ls.append([d["folder_name"], "文件夹", "文件夹", d["last_modified"]])
        else:
            data_ls.append([d["file_name"], 
                            f'{d["size"] / (1024 * 1024):.2f} MB',
                            "文件",
                            d["last_modified"]])

    code = utils.get_select_table(
        ["文件(文件夹)名称", "文件大小", "文件类型", "最近修改时间"],
        data_ls,
        "link_download",
        []
    )
    return "解析成功", code


def download_btn_click(link_content, save_path):
    global content_list
    if not content_list:
        return "请先解析链接", None
    if not save_path:
        return "请先输入保存路径", None
    if not link_content:
        return "请先解析链接", None
    if link_content not in content_list:
        return "请选择要下载的文件", None

    file_name = link_content["file_name"]
    file_path = link_content["file_path"]
    download_url = f"https://cloud.tsinghua.edu.cn/d/{file_path}?dl=1"
    utils.download_file(download_url, save_path, file_name)
    return "下载成功", None



def get_link_download_tab():


    with gr.TabItem("分享链接下载") as tab:
        info = gr.Label(label="消息提示")

        share_link = gr.Textbox(label="分享链接", lines=1)
        save_path= gr.Textbox(label="保存路径", lines=1)
        parse_btn = gr.Button("解析")
        link_content = gr.HTML(label="链接内容")
        download_btn = gr.Button("下载")

        parse_btn.click(fn=parse_btn_click,
                        inputs=[share_link],
                        outputs=[info, link_content])
        

    return tab








