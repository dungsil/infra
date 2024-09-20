# 서버 초기 설정 스크립트
################################################################################
#
# 기본적인 서버 구성 및 보안 설정을 위한 스크립트로 실행 이후 서버 재부팅 권장
#
# 환경변수:
# INIT_HOSTNAME: 서버 호스트 명
# INIT_USER_ID: 서버의 접근할 기본 사용자 계정의 UID
# INIT_USERNAME: 서버의 접근할 기본 사용자 계정
# INIT_USER_SSH_KEY: 사용자의 SSH 공개키
# INIT_TS_AUTH_KEY: Tailscale 인증 키

# 호스트명 설정
sudo hostnamectl set-hostname ${INIT_HOSTNAME}

# 타임존 설정
sudo timedatectl set-timezone 'Asia/Seoul'

# 시스템 업데이트
sudo apt update && sudo apt upgrade -y

# 사용자 생성
sudo useradd -m --shell /bin/bash -u ${INIT_USER_ID} -U ${INIT_USERNAME}
sudo usermod -a -G sudo ${INIT_USERNAME}
sudo passwd -d ${INIT_USERNAME}

# 사용자 SSH 키 삽입
mkdir /home/${INIT_USERNAME}/.ssh
echo "${INIT_USER_SSH_KEY}" >> /home/${INIT_USERNAME}/.ssh/authorized_keys
sudo chown ${INIT_USERNAME}:${INIT_USERNAME} -R /home/${INIT_USERNAME}
sudo chmod 700 /home/${INIT_USERNAME}/.ssh
sudo chmod 600 /home/${INIT_USERNAME}/.ssh/authorized_keys

# TailScale 설치
curl -fsSL https://tailscale.com/install.sh | sh && sudo tailscale up --auth-key=${INIT_TS_AUTH_KEY}

# 도커 설치
sudo apt-get install ca-certificates curl gnupg -y
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -a -G docker ${INIT_USERNAME}
sudo /usr/lib/systemd/systemd-sysv-install enable docker
docker run --rm hello-world
docker image rm hello-world

# fail2ban 설치
sudo apt install fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban

# 방화벽
sudo ufw enable
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow from 100.64.0.0/10 to any port 22 proto tcp
sudo ufw reload
