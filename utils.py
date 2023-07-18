import gradio as gr
import shared
import os
import time
import html
from typing import List, AnyStr



def webpath(fn):
    web_path = fn.replace('\\', '/')
    return f'file={web_path}?{os.path.getmtime(fn)}'

def stylesheet(fn):
    return f'<link rel="stylesheet" property="stylesheet" href="{webpath(fn)}">'

def install_script():
    script_js = "script.js"
    js = f'<script type="text/javascript" src="{webpath(script_js)}"></script>\n'
    css = stylesheet("style.css")
    def template_response(*args, **kwargs):
        res = shared.GradioTemplateResponseOriginal(*args, **kwargs)
        res.body = res.body.replace(b'</head>', f'{js}</head>'.encode("utf8"))
        res.body = res.body.replace(b'</body>', f'{css}</body>'.encode("utf8"))
        res.init_headers()
        return res

    gr.routes.templates.TemplateResponse = template_response


def get_select_table(headers: List[AnyStr], data: List[List], table_mark:AnyStr, selected_index:List):
    """
    each item was identy by select_{index}
    """
    th_code = "<th>check</th>"
    for i in range(len(headers)):
        th_code += f"<th>{html.escape(headers[i])}</th>"


    code = f"""<!-- {time.time()} -->
    <div>
    <table id="{html.escape(table_mark)}">
        <thead>
            <tr>
                {th_code}
            </tr>
        </thead>
        <tbody>
    """

    for index, d in zip(range(len(data)), data):
        td_code = f"""<tr>
                    <td>
                        <label class="container">
                        <input name="select_{index}" type="checkbox" {"checked" if index in selected_index else ''}>
                        <span class="checkmark"></span>
                        </label>
                    </td>"""
        for i in range(len(headers)):
            if i < len(d):
                td_code += f"<td>{html.escape(str(d[i]))}</td>"
            else:
                td_code += "<td></td>"
        code += td_code
        code += "</tr>"


    code += """</tbody></table></div>"""
    
    return code