#!/bin/bash
set -x
# python3 executable
if [[ -z "${python_cmd}" ]]
then
    python_cmd="/Users/xxy/miniforge3/bin/python"
fi

# python3 venv without trailing slash (defaults to ${install_dir}/${clone_dir}/venv)
if [[ -z "${venv_dir}" ]]
then
    venv_dir="venv"
fi

if [[ ! -d "${venv_dir}" ]]
then
    "${python_cmd}" -m venv "${venv_dir}"
fi


# shellcheck source=/dev/null
if [[ -f "${venv_dir}"/bin/activate ]]
then
    source "${venv_dir}"/bin/activate
    # install requirements anyway
    "${venv_dir}/bin/python" -m pip install -r requirements.txt -i https://pypi.tuna.tsinghua.edu.cn/simple
    echo run app
    "${venv_dir}/bin/python" app.py
else
    printf "\n%s\n" "${delimiter}"
    printf "\e[1m\e[31mERROR: Cannot activate python venv, aborting...\e[0m"
    printf "\n%s\n" "${delimiter}"
    exit 1
fi

