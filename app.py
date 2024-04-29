import gradio as gr
import requests
import logging
import re
import shared
import utils
from cloud import get_cloud_tab
from link_download import get_link_download_tab
from tsinghua_email import get_email_tab

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
    info = s.post(login_uri, data=values, headers=shared.headers).text
    
    ticket = re.findall('ticket=(.+?)"', info)
    successful = len(ticket) > 0
    if successful:
        logger.info(f"{username} login successs")
        # 拿ticket, 随后可以拿到sessionid
        res_cloud = s.get(f"https://cloud.tsinghua.edu.cn/tsinghua-auth/callback/?ticket={ticket[0]}")

        if res_cloud.status_code == 200:
            shared.cookies = s.cookies
            print(shared.cookies)
            return "登录成功"
        else:
            return "清华云盘登录失败, 请检查用户名密码"
            
    else:
        logger.error(f"{username} login failed")
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


        get_cloud_tab()

        get_link_download_tab()
        
        get_email_tab()


demo.queue().launch()