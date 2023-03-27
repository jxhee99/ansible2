#!/bin/bash
clear
# cat << EOF

# 다음 중 하나를 선택하시오.
# ###############################################
# # 1) root(.)/com DNS 서버 설정
# # 2) 일반 DNS 서버 설정 (ex. example.com)
# ###############################################

# EOF

# echo -n "당신의 선택은? (1/2) : "
# read CHOICE

# # echo $CHOICE
# case $CHOICE in
#     1) echo "root(.)/com DNS 서버 설정" ;;
#     2) echo "일반 DNS 서버 설정 (ex. example.com)" ;;
#     *) echo "[ FAIL ] 잘못된 선택을 했습니다. 종료!"
# esac

cat << EOF
############################################### 
# 일반 DNS 서버 설정 (ex. example.com)
* 0) WORK 변수 설정하기
* 1) inventory 파일 설정
* 2) installdns.sh 실행
###############################################

EOF

########################################
# Must be configure the WORK vairable.
WORK=example,test,soldesk
########################################

while true
do
    echo -n "설정하고 싶은 도메인을 입력하십시오(ex: example) : "
    read SPLIT_DOMAIN
    echo -n "설정 하고 싶은 DNS서버 IP를 입력하십시오(ex: 192.168.10.10) : "
    read IP

    echo
    echo "Domain name: $SPLIT_DOMAIN.com"
    echo "IP address: $IP"
    echo
    echo -n "다음 정보가 맞습니까? (y/n) : "
    read CHOICE
    case $CHOICE in
        y) break ;;
        n) continue ;;
        *) echo "[ WRAN ] 잘못 입력하셨습니다." ;;
    esac
done

#1. templates/com.zone.j2 내용추가
SHORT_DOMAIN=$SPLIT_DOMAIN
cat << EOF >> templates/com.zone.j2
$SHORT_DOMAIN         IN  NS  ns1.$SHORT_DOMAIN
ns1.$SHORT_DOMAIN     IN  A   $IP
EOF 

#2. templates/com.rev.j2 내용 추가
LAST_IP=$(echo $IP | awk -F. '{print $4}')
cat << EOF >> templates/com.rev.j2
$LAST_IP                  IN  PTR         ns1.$SHORT_DOMAIN.com.
EOF

#3. group_vars/domain.yml 파일 생성 및 내용 추가
cat << EOF > group_vars/$SHORT_DOMAIN.yml
domain_dns_reverse_num: $LAST_IP
domain: $SHORT_DOMAIN.com
split_domain: $SHORT_DOMAIN
EOF

#4. playbook_domain.yml 파일 편집
cat << EOF > playbook_domain.yml
---
- name: DNS 서버 설정 
  hosts: $WORK
  gather_facts: no
  tasks:
    - name: DNS 초기 설정
      include_tasks: tasks/dns_init_configuration.yml

    - name: DNS 확장 설정
      include_tasks: tasks/dns_domain_configuration.yml

    - name: DNS 클라이언트 설정
      include_tasks: tasks/dns_client_configuration.yml

  handlers:
    - name: restart named
      service:
        name: named
        state: restarted
EOF 

#5. playbook
# ansible-playbook play