# icloud api接口口





## 获取仓库列表



| Method | GET                                                          |
| ------ | ------------------------------------------------------------ |
| URL    | https://cloud.tsinghua.edu.cn/api/v2.1/repos/?type=mine      |
| Cookie | sessionid=xxxx                                               |
|        | "repos": [<br/>        {<br/>            "type": "mine",<br/>            "repo_id": "17966538-6682-437f-acf0-e3d30113253e",<br/>            "repo_name": "ADL138",<br/>            "owner_email": "2019011831@tsinghua.edu.cn",<br/>            "owner_name": "\u9879\u6668\u4e1c",<br/>            "owner_contact_email": "xcd19@mails.tsinghua.edu.cn",<br/>            "last_modified": "2023-06-04T12:17:56+08:00",<br/>            "modifier_email": "2019011831@tsinghua.edu.cn",<br/>            "modifier_name": "\u9879\u6668\u4e1c",<br/>            "modifier_contact_email": "xcd19@mails.tsinghua.edu.cn",<br/>            "size": 477657697,<br/>            "encrypted": false,<br/>            "permission": "rw",<br/>            "starred": false,<br/>            "status": "normal",<br/>            "salt": "",<br/>            "storage_name": "MinIO 2 24",<br/>            "storage_id": "MinIO_2_24"<br/>        },<br/>        { |





## 获取文件列表

| Method   | GET                                                          |
| -------- | ------------------------------------------------------------ |
| URL      | https://cloud.tsinghua.edu.cn/api/v2.1/repos/<repo_id>/dir/  |
| Cookie   | sessionid=xxxx                                               |
| 返回样例 | {<br/>    "user_perm": "rw",<br/>    "dir_id": "1bd512ecdd9325e2a39d9350f1e5c36a0fac2a92",<br/>    "dirent_list": [<br/>        {<br/>            "type": "file",<br/>            "id": "90931f7bc58b554f5306c6edbdf0ee49d8632cce",<br/>            "name": "\u8bc1\u4e66.zip",<br/>            "mtime": 1607144411,<br/>            "permission": "rw",<br/>            "parent_dir": "/",<br/>            "size": 315434701,<br/>            "modifier_email": "2019011831@tsinghua.edu.cn",<br/>            "modifier_name": "\u9879\u6668\u4e1c",<br/>            "modifier_contact_email": "xcd19@mails.tsinghua.edu.cn",<br/>            "is_locked": false,<br/>            "lock_time": 0,<br/>            "lock_owner": "",<br/>            "lock_owner_name": "",<br/>            "lock_owner_contact_email": "",<br/>            "locked_by_me": false,<br/>            "starred": false<br/>        },<br/>        {<br/>            "type": "file",<br/>            "id": "255b1f92d7adc8b7906af91767854a48006cba43",<br/>            "name": "\u8f9b\u5df4.mp4",<br/>            "mtime": 1605012248,<br/>            "permission": "rw",<br/>            "parent_dir": "/",<br/>            "size": 133992044,<br/>            "modifier_email": "2019011831@tsinghua.edu.cn",<br/>            "modifier_name": "\u9879\u6668\u4e1c",<br/>            "modifier_contact_email": "xcd19@mails.tsinghua.edu.cn",<br/>            "is_locked": false,<br/>            "lock_time": 0,<br/>            "lock_owner": "",<br/>            "lock_owner_name": "",<br/>            "lock_owner_contact_email": "",<br/>            "locked_by_me": false,<br/>            "starred": false<br/>        }<br/>    ]<br/>} |



## 文件下载

| Method | GET                                                          |
| ------ | ------------------------------------------------------------ |
| URL    | https://cloud.tsinghua.edu.cn/lib/<repo_id>/file/<file_name>?dl=1 |
| Cookie | sessionid=xxxx                                               |
|        |                                                              |





## 查询某个文件夹的内容



| Method | GET                                                          |
| ------ | ------------------------------------------------------------ |
| URL    | https://cloud.tsinghua.edu.cn/api/v2.1/repos/<reop_id>/dir/?p=%2Fxcd%2F940870563%2FFileRecv&with_thumbnail=true |
|        |                                                              |
|        | {<br/>    "user_perm": "rw",<br/>    "dir_id": "64019f91d1b19afa3542f3023435ae14a957dfdc",<br/>    "dirent_list": [<br/>        {<br/>            "type": "dir",<br/>            "id": "f4ab813da5af8d52f9e911c19f45662f95800c3d",<br/>            "name": "MobileFile",<br/>            "mtime": 1417342402,<br/>            "permission": "rw",<br/>            "parent_dir": "/xcd/940870563/FileRecv/",<br/>            "starred": false<br/>        },<br/>        {<br/>            "type": "file",<br/>            "id": "418995f9b498e2185adbe920a9191b4bcaece880",<br/>            "name": "Adobe CS6 \u7cfb\u5217\u8f6f\u4ef6\u901a\u7528\u7834\u89e3\u8865\u4e01 (amtlib.dll \u542b32\u4f4d\u4e0e64\u4f4d).rar",<br/>            "mtime": 1417344922,<br/>            "permission": "rw",<br/>            "parent_dir": "/xcd/940870563/FileRecv/",<br/>            "size": 1289281,<br/>            "modifier_email": "2019011831@tsinghua.edu.cn",<br/>            "modifier_name": "\u9879\u6668\u4e1c",<br/>            "modifier_contact_email": "xcd19@mails.tsinghua.edu.cn",<br/>            "is_locked": false,<br/>            "lock_time": 0,<br/>            "lock_owner": "",<br/>            "lock_owner_name": "",<br/>            "lock_owner_contact_email": "",<br/>            "locked_by_me": false,<br/>            "starred": false<br/>        }, |





## 登陆

授权后要取ticket, 详细见代码。









# 清华邮箱相关的接口



## 登录



```
r = s.post("https://mails.tsinghua.edu.cn/coremail/index.jsp?cus=1", 
           data={
                "locale": "zh_CN",
                "nodetect": "false",
                "destURL": "",
                "supportLoginDevice": "true",
                "accessToken": "",
                "timestamp": "",
                "signature": "",
                "nonce": "",
                "device": '{"uuid":"webmail_mac","imie":"webmail_mac","friendlyName":"chrome 114","model":"mac","os":"macosx","osLanguage":"zh-CN","deviceType":"Webmail"}',
                "supportDynamicPwd": "true",
                "supportBind2FA": "true",
                "authorizeDevice": "",
                "loginType": "",
                "uid": "xxx",
                "domain": "mails.tsinghua.edu.cn",
                "password": "xxx",
                "action:login": ""
           },)
```

此外还需要获取`sid`, 可以通过返回的网页中提取:

```
res = re.findall(r'sid = "(\w+)";', r.text)
```









## 获取邮件列表

| Method | post                                                         |
| ------ | ------------------------------------------------------------ |
| URL    | "https://mails.tsinghua.edu.cn/coremail/XT3/mbox/getListDatas.jsp?sid={sid}&fid=1" |
| 返回值 |                                                              |
|        |                                                              |

返回值样例: 一个很丑的json

```
{
'offset':0,
'unreadMessage':205,
'total':1176,
'msgList':[{
'addT':'postmaster@tsinghua.edu.cn',
'add':'postmaster',
'icon':{
'm_icon':'UNREAD',
'p_icon':'NORMAL',
'att_icon':'',
'avs_icon':'UNSCANED',
'flagged_icon':'flagged_false'},
'item':{
'id':'1:1tbiAQELAWSvNiHh0AAAsn',
'fid':1,
'size':3099,
'from':'postmaster@tsinghua.edu.cn',
'to':'xcd19@mails.tsinghua.edu.cn',
'subject':'垃圾邮件通知目录摘要/Spam notification Abstract',
'sentDate':new Date(2023,6,14,0,31,12),
'receivedDate':new Date(2023,6,14,0,32,52),
'priority':3,
'backgroundColor':0,
'antiVirusStatus':'unscaned',
'label0':0,
'flags':{
'system':true,
'report':true},
'hmid':'<64B026D0.0B7537.40247@app-1>'}},
```







## 邮件内容

返回的是html的文件

| Method | get                                                          |
| ------ | ------------------------------------------------------------ |
|        |                                                              |
| url    | “https://mails.tsinghua.edu.cn/coremail/XT3/mbox/viewMailHTML.jsp?mid={mid,在邮件列表中}&partId=0&isSearch=&priority=&supportSMIME=&striptTrs=true&mboxa=&sandbox=1” |
|        |                                                              |





## 下载附件



| Method | post                                                         |
| ------ | ------------------------------------------------------------ |
|        | https://mails.tsinghua.edu.cn/coremail/XT3/mbox/allDownload.jsp?sid=CACScHQQVEJfcAeOOwjXVevmplIgiKWO&mid={mid,在邮件列表中}&mboxa= |
|        |                                                              |
|        |                                                              |

