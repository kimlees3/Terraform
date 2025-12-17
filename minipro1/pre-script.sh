#!/bin/bash

# 아래 스크립트 내용 중 실패하면 바로 종료
set -e 

# 프로젝트 작업 폴더(code)
DIR=$HOME/tf/minipro1

cat <<EOF
#############################################################
#  다음 과정은 키 쌍을 생성하고, 개발자 환경을 구축합니다.  #
#############################################################
EOF

# 키 쌍 입력
echo -n "[ INFO ] 키 쌍 이름을 입력하시오(예: mykeypair): "
read FILE

# 키 쌍 생성
ssh-keygen -t rsa -N "" -f ~/.ssh/$FILE \
  && echo "[  OK  ] 키 쌍이 생성되었습니다."

echo "[ INFO ] 개발자 환경을 구축합니다."
cd $DIR

sed -i "s/mykeypair/$FILE/" $DIR/main.tf

terraform init
terraform plan -auto-approve
terraform apply -auto-approve \
  && echo "[  OK  ] 인프라가 완성되었습니다. 다음 스탭을 진행합니다."
