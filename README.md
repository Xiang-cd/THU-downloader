# 清华云盘批量下载工具

如果你苦恼于需要大规模迁移清华云盘中的内容但不像手动逐个点击下载, 那这个工具会很实用! 如果这个工具对你有用, 可以给个star~



TODO:

- [ ] windows bat脚本
- [ ] ~~如何获取sessionid~~
- [x] 写个登录界面
- [ ] 更细粒度选择
- [ ] 更高并发

使用问题可以联系作者微信`xxyaw-`。



### 使用方法(路径中需要有能够使用的python3环境):

mac, linux用户, clone后直接运行, 代码会自动搭建虚拟环境:
```shell
./run.sh
```

如果你对python环境管理很熟悉, 可以在本地进行依赖库的安装:

```
pip install gradio==3.35.2 -i https://pypi.tuna.tsinghua.edu.cn/simple
gradio app.py
```



随后点击生成的链接`http://127.0.0.1:7861`。

```shell
Launching in *reload mode* on: http://127.0.0.1:7860 (Press CTRL+C to quit)

Watching: '/opt/homebrew/lib/python3.10/site-packages/gradio', '/Users/xxy/Github/icloud-crawl'

Running on local URL:  http://127.0.0.1:7861

To create a public link, set `share=True` in `launch()`.
```

输入用户名和密码, 点击登录, 输入目标的下载路径, 点击全部下载就能将所有的仓库按照原结构下载到目标路径, 如果只希望下载部分仓库, 则在下放的文本中删除不需要的仓库名字, 点击`选择下载`, 则仍然在文本框内的仓库会被下载。

