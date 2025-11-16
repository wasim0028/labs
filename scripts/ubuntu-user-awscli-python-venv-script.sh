#!/bin/bash
wget https://raw.githubusercontent.com/wasim0028/labs/refs/heads/master/scripts/awscli.sh
bash awscli.sh
aws --version
wget https://raw.githubusercontent.com/wasim0028/labs/refs/heads/master/scripts/setupUser.sh
bash setupUser.sh
python3 -version
sudo apt install python3 python3-dev python3-venv python3-pip -y
pip3 --version
apt list --upgradable
python3 -m venv env
source env/bin/activate
echo "#requirements.txt file" > requirements.txt
pip install Flask
pip install boto3
pip freeze > requirements.txt
