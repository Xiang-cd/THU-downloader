import gevent.monkey
gevent.monkey.patch_all(ssl=False, subprocess=False, thread=False, time=False)

import gradio as gr
import requests
import logging
import re
import shared
import utils


user_agent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.130 Safari/537.36'
headers = {'User-Agent': user_agent, 'Connection': 'keep-alive'}


if not hasattr(shared, 'GradioTemplateResponseOriginal'):
    shared.GradioTemplateResponseOriginal = gr.routes.templates.TemplateResponse


logging.basicConfig(filename="dowload.log",
                    filemode='a')
logger = logging.getLogger(__file__)
logger.setLevel("INFO")



def login(username, password, progress=gr.Progress(track_tqdm=True)):
    global global_repos
    s = requests.Session()
    login_uri = 'https://id.tsinghua.edu.cn/do/off/ui/auth/login/post/167ed2c25d7f176c20c79e341e2ccdf0/0?/login.do'
    values = {'i_user': username, 'i_pass': password, 'atOnce': 'true'}
    info = s.post(login_uri, data=values).text
    
    ticket = re.findall('ticket=(.+?)"', info)
    successful = len(ticket) > 0
    if successful:
        logger.info(f"{username} login successs")
        res = s.get(f"https://cloud.tsinghua.edu.cn/tsinghua-auth/callback/?ticket={ticket[0]}")
        shared.cookie = s.cookies
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