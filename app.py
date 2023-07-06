import gradio as gr
from tqdm import tqdm
import logging
import os, html, urllib
import urllib.request, http.cookiejar
import re
import ssl
import shared
import utils

ssl._create_default_https_context = ssl._create_unverified_context

user_agent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.130 Safari/537.36'
headers = {'User-Agent': user_agent, 'Connection': 'keep-alive'}
handler = urllib.request.HTTPCookieProcessor(shared.cookie)
opener = urllib.request.build_opener(handler)
urllib.request.install_opener(opener)

if not hasattr(shared, 'GradioTemplateResponseOriginal'):
    shared.GradioTemplateResponseOriginal = gr.routes.templates.TemplateResponse


logging.basicConfig(filename="dowload.log",
                    filemode='a')
logger = logging.getLogger(__file__)
logger.setLevel("INFO")



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
        gr.update()
        return "登录成功"
    else:
        return "登录失败"




with gr.Blocks() as demo:
    utils.install_script()
    with gr.Tabs(elem_id="repo_list") as tabs:
        with gr.TabItem("登录"):
            login_info = gr.Label(label="Output Box")
            username = gr.Textbox(label="username", placeholder="输入用户名")
            password = gr.Textbox(label="password", placeholder="输入密码", type="password")
            login_btn = gr.Button("登录")
            login_btn.click(fn=login, inputs=[username, password], outputs=[login_info])


        from cloud import get_cloud_tab
        get_cloud_tab()

    
demo.queue().launch()