@echo off

REM python executable
if "%python_cmd%"=="" (
    set "python_cmd=python"
)

REM python venv without trailing slash (defaults to %install_dir%/%clone_dir%/venv)
if "%venv_dir%"=="" (
    set "venv_dir=venv"
)

if not exist "%venv_dir%" (
    "%python_cmd%" -m venv "%venv_dir%"
    "%venv_dir%\Scripts\python.exe" -m pip install gradio==3.35.2 -i https://pypi.tuna.tsinghua.edu.cn/simple
)

if exist "%venv_dir%\Scripts\activate.bat" (
    call "%venv_dir%\Scripts\activate.bat"
    echo run app
    gradio app.py
) else (
    echo.
    echo ERROR: Cannot activate Python venv, aborting...
    echo.
    exit /b 1
)