from requests.cookies import RequestsCookieJar
import gradio as gr
import os

# configs
LOG_LEVEL = "INFO"
LOG_FILE = "dowload.log"

# request configs

user_agent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.130 Safari/537.36'
headers = {'User-Agent': user_agent, 'Connection': 'keep-alive'}


cookies = RequestsCookieJar()
sid = ""


