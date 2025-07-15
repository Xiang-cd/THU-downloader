# 清华网络学堂 API 文档

## 基础信息

- **Base URL**: `https://learn.tsinghua.edu.cn`
- **认证方式**: Cookie认证 + CSRF Token
- **内容类型**: `application/json`, `application/x-www-form-urlencoded`, `text/html`

## 认证说明

所有需要认证的API都需要：
1. 携带登录后的Cookie（包含`XSRF-TOKEN`）
2. 在Query参数中添加`_csrf`字段，值为Cookie中的`XSRF-TOKEN`

---

## 1. 认证相关接口

### 1.1 获取登录页面

**接口描述**: 获取登录表单页面，解析登录action地址

```http
GET /
```

**Python示例**:
```python
import requests

response = requests.get('https://learn.tsinghua.edu.cn/')
# 解析HTML获取登录表单的action地址
```

### 1.2 用户登录

**接口描述**: 提交用户名密码进行登录

```http
POST {login_form_action}
```

**请求参数**:
| 参数名 | 类型 | 位置 | 必填 | 说明 |
|--------|------|------|------|------|
| i_user | string | Body | 是 | 用户名 |
| i_pass | string | Body | 是 | 密码 |
| atOnce | boolean | Body | 是 | 固定值true |

**Python示例**:
```python
import requests

# 假设从上一步获取的action地址
login_url = "https://id.tsinghua.edu.cn/do/off/ui/auth/login/post/bb5df85216504820be7bba2b0ae1535b/0?/login.do"

data = {
    'i_user': 'your_username',
    'i_pass': 'your_password',
    'atOnce': True
}

response = requests.post(login_url, data=data)
# 从响应中解析重定向链接和ticket
```

### 1.3 完成认证流程

**接口描述**: 使用ticket完成最终认证

```http
GET /b/j_spring_security_thauth_roaming_entry
```

**请求参数**:
| 参数名 | 类型 | 位置 | 必填 | 说明 |
|--------|------|------|------|------|
| ticket | string | Query | 是 | 从登录响应获取的ticket |

**Python示例**:
```python
import requests

# 保持session以维持cookie
session = requests.Session()

# 第一步：访问重定向URL
session.get(redirect_url)

# 第二步：使用ticket完成认证
params = {'ticket': ticket_from_login_response}
session.get('https://learn.tsinghua.edu.cn/b/j_spring_security_thauth_roaming_entry', params=params)

# 第三步：访问课程页面完成登录
session.get('https://learn.tsinghua.edu.cn/f/wlxt/index/course/student/')

# 获取CSRF token
csrf_token = session.cookies.get('XSRF-TOKEN')
```

---

## 2. 学期管理接口

### 2.1 获取学期列表

**接口描述**: 查询所有可用的学期信息

```http
GET /b/wlxt/kc/v_wlkc_xs_xktjb_coassb/queryxnxq
```

**请求参数**:
| 参数名 | 类型 | 位置 | 必填 | 说明 |
|--------|------|------|------|------|
| _csrf | string | Query | 是 | CSRF Token |

**响应示例**:
```json
["2023-2024-1", "2023-2024-2", "2024-2025-1"]
```

**Python示例**:
```python
import requests

session = requests.Session()
# ... 完成登录获取session和csrf_token ...

params = {
    '_csrf': csrf_token
}

response = session.get(
    'https://learn.tsinghua.edu.cn/b/wlxt/kc/v_wlkc_xs_xktjb_coassb/queryxnxq',
    params=params
)

semester_list = response.json()
print(semester_list)
```

---

## 3. 课程管理接口

### 3.1 获取学期课程列表

**接口描述**: 根据学期ID获取该学期的所有课程

```http
GET /b/wlxt/kc/v_wlkc_xs_xkb_kcb_extend/student/loadCourseBySemesterId/{semester_id}/{language}
```

**路径参数**:
| 参数名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| semester_id | string | 是 | 学期ID，如"2023-2024-1" |
| language | string | 是 | 语言代码，zh或en |

**请求参数**:
| 参数名 | 类型 | 位置 | 必填 | 说明 |
|--------|------|------|------|------|
| _csrf | string | Query | 是 | CSRF Token |

**响应示例**:
```json
{
  "resultList": [
    {
      "wlkcid": "2023-2024-1-12345678-1",
      "kcm": "数据结构",
      "kch": "30240243",
      "ywkcm": "Data Structures",
      "zywkcm": "数据结构",
      "jsm": "张三",
      "jsh": "12345"
    }
  ]
}
```

**Python示例**:
```python
import requests

session = requests.Session()
# ... 完成登录获取session和csrf_token ...

semester_id = "2023-2024-1"
language = "zh"  # 或 "en"

params = {
    '_csrf': csrf_token
}

response = session.get(
    f'https://learn.tsinghua.edu.cn/b/wlxt/kc/v_wlkc_xs_xkb_kcb_extend/student/loadCourseBySemesterId/{semester_id}/{language}',
    params=params
)

courses = response.json()['resultList']
print(courses)
```

---

## 4. 文档资料接口

### 4.1 获取课程文档分类

**接口描述**: 获取指定课程的文档分类列表

```http
GET /b/wlxt/kj/wlkc_kjflb/student/pageList
```

**请求参数**:
| 参数名 | 类型 | 位置 | 必填 | 说明 |
|--------|------|------|------|------|
| wlkcid | string | Query | 是 | 课程ID |
| _csrf | string | Query | 是 | CSRF Token |

**响应示例**:
```json
{
  "object": {
    "rows": [
      {
        "kjflid": "12345",
        "bt": "课件"
      },
      {
        "kjflid": "12346", 
        "bt": "参考资料"
      }
    ]
  }
}
```

**Python示例**:
```python
import requests

session = requests.Session()
# ... 完成登录获取session和csrf_token ...

course_id = "2023-2024-1-12345678-1"

params = {
    'wlkcid': course_id,
    '_csrf': csrf_token
}

response = session.get(
    'https://learn.tsinghua.edu.cn/b/wlxt/kj/wlkc_kjflb/student/pageList',
    params=params
)

doc_classes = response.json()['object']['rows']
print(doc_classes)
```

### 4.2 获取课程文档列表

**接口描述**: 获取指定课程的所有文档文件

```http
GET /b/wlxt/kj/wlkc_kjxxb/student/kjxxbByWlkcidAndSizeForStudent
```

**请求参数**:
| 参数名 | 类型 | 位置 | 必填 | 说明 |
|--------|------|------|------|------|
| wlkcid | string | Query | 是 | 课程ID |
| size | integer | Query | 否 | 返回数量限制，默认200 |
| _csrf | string | Query | 是 | CSRF Token |

**响应示例**:
```json
{
  "object": [
    {
      "wjid": "doc123456",
      "kjflid": "12345",
      "wjlx": "pdf",
      "wjdx": 1048576,
      "bt": "第一章 绪论.pdf",
      "scsj": 1696867200000
    }
  ]
}
```

**Python示例**:
```python
import requests

session = requests.Session()
# ... 完成登录获取session和csrf_token ...

course_id = "2023-2024-1-12345678-1"

params = {
    'wlkcid': course_id,
    'size': 200,
    '_csrf': csrf_token
}

response = session.get(
    'https://learn.tsinghua.edu.cn/b/wlxt/kj/wlkc_kjxxb/student/kjxxbByWlkcidAndSizeForStudent',
    params=params
)

documents = response.json()['object']
print(documents)
```

### 4.3 下载文档文件

**接口描述**: 下载指定的文档文件

```http
GET /b/wlxt/kj/wlkc_kjxxb/student/downloadFile
```

**请求参数**:
| 参数名 | 类型 | 位置 | 必填 | 说明 |
|--------|------|------|------|------|
| sfgk | integer | Query | 是 | 是否公开，固定值0 |
| wjid | string | Query | 是 | 文件ID |
| _csrf | string | Query | 是 | CSRF Token |

**Python示例**:
```python
import requests

session = requests.Session()
# ... 完成登录获取session和csrf_token ...

file_id = "doc123456"

params = {
    'sfgk': 0,
    'wjid': file_id,
    '_csrf': csrf_token
}

response = session.get(
    'https://learn.tsinghua.edu.cn/b/wlxt/kj/wlkc_kjxxb/student/downloadFile',
    params=params,
    stream=True  # 用于下载大文件
)

# 保存文件
with open('downloaded_file.pdf', 'wb') as f:
    for chunk in response.iter_content(chunk_size=8192):
        f.write(chunk)
```

---

## 5. 作业管理接口

### 5.1 获取未完成作业列表

**接口描述**: 获取指定课程的未完成作业

```http
GET /b/wlxt/kczy/zy/student/index/zyListWj
```

**请求参数**:
| 参数名 | 类型 | 位置 | 必填 | 说明 |
|--------|------|------|------|------|
| wlkcid | string | Query | 是 | 课程ID |
| size | integer | Query | 否 | 返回数量限制，默认200 |
| _csrf | string | Query | 是 | CSRF Token |

**响应示例**:
```json
{
  "object": {
    "aaData": [
      {
        "zyid": "hw123456",
        "bt": "第一章练习题",
        "kssj": 1696867200000,
        "jzsj": 1697472000000,
        "wz": 1
      }
    ]
  }
}
```

**Python示例**:
```python
import requests

session = requests.Session()
# ... 完成登录获取session和csrf_token ...

course_id = "2023-2024-1-12345678-1"

params = {
    'wlkcid': course_id,
    'size': 200,
    '_csrf': csrf_token
}

response = session.get(
    'https://learn.tsinghua.edu.cn/b/wlxt/kczy/zy/student/index/zyListWj',
    params=params
)

unfinished_homeworks = response.json()['object']['aaData'] or []
print(unfinished_homeworks)
```

### 5.2 获取已完成未批改作业列表

**接口描述**: 获取指定课程的已完成但未批改作业

```http
GET /b/wlxt/kczy/zy/student/index/zyListYjwg
```

**请求参数**:
| 参数名 | 类型 | 位置 | 必填 | 说明 |
|--------|------|------|------|------|
| wlkcid | string | Query | 是 | 课程ID |
| size | integer | Query | 否 | 返回数量限制，默认200 |
| _csrf | string | Query | 是 | CSRF Token |

**Python示例**:
```python
import requests

session = requests.Session()
# ... 完成登录获取session和csrf_token ...

course_id = "2023-2024-1-12345678-1"

params = {
    'wlkcid': course_id,
    'size': 200,
    '_csrf': csrf_token
}

response = session.get(
    'https://learn.tsinghua.edu.cn/b/wlxt/kczy/zy/student/index/zyListYjwg',
    params=params
)

submitted_homeworks = response.json()['object']['aaData'] or []
print(submitted_homeworks)
```

### 5.3 获取已批改作业列表

**接口描述**: 获取指定课程的已批改作业

```http
GET /b/wlxt/kczy/zy/student/index/zyListYpg
```

**请求参数**:
| 参数名 | 类型 | 位置 | 必填 | 说明 |
|--------|------|------|------|------|
| wlkcid | string | Query | 是 | 课程ID |
| size | integer | Query | 否 | 返回数量限制，默认200 |
| _csrf | string | Query | 是 | CSRF Token |

**Python示例**:
```python
import requests

session = requests.Session()
# ... 完成登录获取session和csrf_token ...

course_id = "2023-2024-1-12345678-1"

params = {
    'wlkcid': course_id,
    'size': 200,
    '_csrf': csrf_token
}

response = session.get(
    'https://learn.tsinghua.edu.cn/b/wlxt/kczy/zy/student/index/zyListYpg',
    params=params
)

graded_homeworks = response.json()['object']['aaData'] or []
print(graded_homeworks)
```

### 5.4 获取作业详情

**接口描述**: 获取作业的详细信息，包括题目、答案、提交内容、批改结果等

```http
GET /f/wlxt/kczy/zy/student/viewCj
```

**请求参数**:
| 参数名 | 类型 | 位置 | 必填 | 说明 |
|--------|------|------|------|------|
| wlkcid | string | Query | 是 | 课程ID |
| xszyid | string | Query | 是 | 学生作业ID |
| zyid | string | Query | 是 | 作业ID |
| _csrf | string | Query | 是 | CSRF Token |

**响应**: 返回HTML页面，需要解析获取详细信息

**Python示例**:
```python
import requests
from bs4 import BeautifulSoup

session = requests.Session()
# ... 完成登录获取session和csrf_token ...

params = {
    'wlkcid': 'course_id',
    'xszyid': 'student_homework_id', 
    'zyid': 'homework_id',
    '_csrf': csrf_token
}

response = session.get(
    'https://learn.tsinghua.edu.cn/f/wlxt/kczy/zy/student/viewCj',
    params=params
)

# 解析HTML获取详细信息
soup = BeautifulSoup(response.text, 'html.parser')
# 根据HTML结构解析具体内容...
```

---

## 数据模型说明

### 作业字段映射
| API字段 | 中文含义 | 数据类型 | 说明 |
|---------|----------|----------|------|
| zyid | 作业ID | string | 作业唯一标识 |
| bt | 标题 | string | 作业标题 |
| kssj | 开始时间 | timestamp | Unix时间戳 |
| jzsj | 截止时间 | timestamp | Unix时间戳 |
| scsj | 提交时间 | timestamp | Unix时间戳 |
| cj | 成绩 | string/float | 作业成绩 |
| jsm | 批改教师 | string | 教师姓名 |
| pysj | 批改时间 | timestamp | Unix时间戳 |
| pynr | 批改内容 | string | 教师评语 |
| wz | 序号 | integer | 作业序号 |

### 课程字段映射
| API字段 | 中文含义 | 数据类型 | 说明 |
|---------|----------|----------|------|
| wlkcid | 课程ID | string | 课程唯一标识 |
| kcm | 中文课程名 | string | 课程中文名称 |
| kch | 课程号 | string | 课程编号 |
| ywkcm | 英文课程名 | string | 课程英文名称 |
| zywkcm | 课程全名 | string | 课程完整名称 |
| jsm | 教师姓名 | string | 任课教师 |
| jsh | 教师号 | string | 教师编号 |

### 文档字段映射
| API字段 | 中文含义 | 数据类型 | 说明 |
|---------|----------|----------|------|
| wjid | 文件ID | string | 文件唯一标识 |
| kjflid | 分类ID | string | 文档分类ID |
| wjlx | 文件类型 | string | 文件扩展名 |
| wjdx | 文件大小 | integer | 字节数 |
| bt | 文件标题 | string | 文件名称 |
| scsj | 上传时间 | timestamp | Unix时间戳 |

---

## 完整使用示例

```python
import requests
from bs4 import BeautifulSoup
import urllib.parse

class ThuLearnAPI:
    def __init__(self):
        self.session = requests.Session()
        self.csrf_token = None
        self.base_url = "https://learn.tsinghua.edu.cn"
    
    def login(self, username, password):
        """完整登录流程"""
        # 1. 获取登录页面
        response = self.session.get(f"{self.base_url}/")
        soup = BeautifulSoup(response.text, 'html.parser')
        login_form = soup.select_one("#loginForm")
        action = login_form["action"]
        
        # 2. 提交登录信息
        login_data = {
            'i_user': username,
            'i_pass': password,
            'atOnce': True
        }
        response = self.session.post(action, data=login_data)
        
        # 3. 解析重定向和ticket
        soup = BeautifulSoup(response.text, 'html.parser')
        a = soup.select_one("a")
        href = a["href"]
        parse_result = urllib.parse.urlparse(href)
        query = urllib.parse.parse_qs(parse_result.query)
        ticket = query["ticket"][0]
        
        # 4. 完成认证流程
        self.session.get(href)
        self.session.get(f"{self.base_url}/b/j_spring_security_thauth_roaming_entry", 
                        params={"ticket": ticket})
        self.session.get(f"{self.base_url}/f/wlxt/index/course/student/")
        
        # 5. 获取CSRF token
        self.csrf_token = self.session.cookies.get('XSRF-TOKEN')
        
    def get_semesters(self):
        """获取学期列表"""
        params = {'_csrf': self.csrf_token}
        response = self.session.get(
            f"{self.base_url}/b/wlxt/kc/v_wlkc_xs_xktjb_coassb/queryxnxq",
            params=params
        )
        return response.json()
    
    def get_courses(self, semester_id, language='zh'):
        """获取课程列表"""
        params = {'_csrf': self.csrf_token}
        response = self.session.get(
            f"{self.base_url}/b/wlxt/kc/v_wlkc_xs_xkb_kcb_extend/student/loadCourseBySemesterId/{semester_id}/{language}",
            params=params
        )
        return response.json()['resultList']
    
    def get_homeworks(self, course_id, homework_type='zyListWj'):
        """获取作业列表"""
        params = {
            'wlkcid': course_id,
            'size': 200,
            '_csrf': self.csrf_token
        }
        response = self.session.get(
            f"{self.base_url}/b/wlxt/kczy/zy/student/index/{homework_type}",
            params=params
        )
        return response.json()['object']['aaData'] or []

# 使用示例
api = ThuLearnAPI()
api.login('your_username', 'your_password')

semesters = api.get_semesters()
courses = api.get_courses(semesters[0])
homeworks = api.get_homeworks(courses[0]['wlkcid'])
```

---

## 错误处理说明

### 常见错误码
- **401 Unauthorized**: 未登录或登录过期
- **403 Forbidden**: 无权限访问
- **404 Not Found**: 资源不存在
- **500 Internal Server Error**: 服务器内部错误

### 错误处理建议
```python
def safe_request(self, method, url, **kwargs):
    """带错误处理的请求方法"""
    try:
        response = self.session.request(method, url, **kwargs)
        response.raise_for_status()
        return response
    except requests.exceptions.HTTPError as e:
        if e.response.status_code == 401:
            # 重新登录
            self.login(username, password)
            return self.session.request(method, url, **kwargs)
        else:
            raise e
    except requests.exceptions.RequestException as e:
        # 网络错误，可以实现重试机制
        raise e
```