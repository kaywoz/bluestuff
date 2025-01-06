# a sample forensics pipeline for dftimewolf, plaso, timesketch etc.
# run as root
#!/bin/bash

#logging
#exec 3>&1 4>&2
#trap 'exec 2>&4 1>&3' 0 1 2 3
#exec 1>log.out 2>&1

# prep with pre-req for os
mkdir /workspace
mkdir /workspace/dftimewolf
mkdir /workspace/timesketch
mkdir /workspace/workfiles
chown root /workspace
cd /workspace
apt update && sudo apt upgrade -y
apt install -y python3 python3-pip python3-venv git unzip nano
export PATH="$HOME/.local/bin:$PATH"
python3 --version
pip --version
#________________________
## rclone

curl https://rclone.org/install.sh | sudo bash
mkdir /root/.config/rclone/
curl https://raw.githubusercontent.com/kaywoz/bluestuff/refs/heads/main/other/samples/rclone/rclone.conf > /root/.config/rclone/rclone.conf

#________________________
## docker
curl -sSL https://get.docker.com/ | sh

#_________________________
## plaso
docker run log2timeline/plaso --name plaso log2timeline.py --version

#_________________________
## dftimewolf
git clone https://github.com/log2timeline/dftimewolf.git
cd dftimewolf

python3 -m venv venv
source venv/bin/activate
venv/bin/pip install poetry
venv/bin/poetry install
venv/bin/poetry run dftimewolf -h

#_________________________
## timesketch
cd /workspace/timesketch/
curl -s -O https://raw.githubusercontent.com/google/timesketch/master/contrib/deploy_timesketch.sh
chmod 755 deploy_timesketch.sh
./deploy_timesketch.sh --start-container --skip-create-user
cd timesketch/
docker compose exec timesketch-web tsctl create-user user --password password
docker compose restart ## restart compose again in case of 502 for timesketch
#_________________________
## copy workfiles


##have to do work on selection of files, form is 2024-12-04T14;18;24.566Z-hostname.sub.domain.com, by date?, by hostname input? some logic?
#cp /tmp/work/ /workspace/workfiles/
rclone copy /tmp/work/ /workspace/workfiles/ -P
#rclone copy source:/ /workspace/workfiles -P
#unzip /workspace/workfiles/* ###TODO
### maybe rclone move instead and continuously download all files and rerun jobs for new timelines
#_________________________
## run job

cd /workspace/dftimewolf
source venv/bin/activate
#venv/bin/poetry run dftimewolf plaso_ts --timesketch_endpoint http://localhost /workspace/workfiles
##venv/bin/poetry run yes $'http://127.0.0.1' | dftimewolf plaso_ts /workspace/workfiles
venv/bin/poetry run dftimewolf plaso_ts /workspace/workfiles --timesketch_endpoint http://localhost/ --incident_id "$hostname" --timesketch_username user --timesketch_password password
