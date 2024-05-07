import asyncio
from pyppeteer import launch
import re,os

def set_value(page, selector, value):
    return page.evaluate(f'''(selector, value) => {{
        document.querySelector(selector).value = value;
    }}''', selector, value)

def get_value(page, selector):
    return page.evaluate(f'''(selector) => {{
        return document.querySelector(selector).value;
    }}''', selector)


async def main():
    browser = await launch()
    page = await browser.newPage()
        # 监听网络请求
    # def request_callback(request):
    #     if "img" in request.url.lower() or "image" in request.url.lower()\
    #         or "png" in request.url.lower() or "jpg" in request.url.lower():
    #         return
    #     print('Request URL:', request.url)
    #     print('Request Method:', request.method)
    #     print('Request Headers:', request.headers)
    #     print('Request Post Data:', request.postData)
    #     print()
    # page.on('request', request_callback)
    coremail = None
    sid = None
    def response_callback(response):
        nonlocal coremail, sid
        if "set-cookie" in response.headers:
            if "Coremail.sid" in response.headers["set-cookie"]:
                sid = re.search(r'Coremail.sid=(\w+)', response.headers["set-cookie"]).group(1)
                print(f"Coremail.sid={sid};")
            elif "Coremail" in response.headers["set-cookie"]:
                coremail = re.search(r'Coremail=(\w+)', response.headers["set-cookie"]).group(1)
                print(f"Coremail={coremail};")

    # 监听页面的请求事件
    page.on('response', response_callback)
    
    await page.goto('https://mails.tsinghua.edu.cn/')
    await asyncio.sleep(2) # wait for 2 seconds for page to load

    print("username:")
    username = input().strip()
    print("password:")
    password = input().strip()
    
    button = await page.xpath("/html/body/div[3]/div[4]/div[2]/div[3]/div[1]/form/div[3]/button")
    if not button:
        return "加载错误"
    else:
        button = button[0]
    
    uname_selector = 'input[name="uid"]'
    await set_value(page, uname_selector, username)
    password_selector = 'input[name="password"]'
    await set_value(page, password_selector, password)

    await button.click()
    await asyncio.sleep(2) # wait for 2 seconds for page to load
    await page.screenshot({'path': 'afterlogin.png'})
    
    msg_selector = 'input[class="u-input mgr"]'
    second_button = await page.xpath("/html/body/div[3]/div[4]/div[2]/div[3]/div[1]/div/div[3]/input[1]")
    if not second_button:
        return "用户名或者密码错误"
    else:
        second_button = second_button[0]
    
    print("message:", flush=True)
    msg = input().strip()
    await set_value(page, msg_selector, msg)
    await second_button.click()
    await asyncio.sleep(2) # wait for 2 seconds for page to load

    await page.screenshot({'path': 'aftermessage.png'})
    
    ele = await page.xpath("/html/body/section/article/section/header/div/a/img")
    if not ele:
        return "验证码错误"
    else:
        ele = ele[0]
    await browser.close()
    return "成功"

if __name__ == "__main__":
    status = asyncio.get_event_loop().run_until_complete(main()) # run the main function
    print(status)
