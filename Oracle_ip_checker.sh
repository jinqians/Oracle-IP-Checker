#!/bin/bash

# 更新APT包索引并安装必要的工具
install_tools() {
    echo "更新APT包索引..."
    sudo apt-get update -y
    echo "检查并安装必要的工具..."
    if ! command -v curl &> /dev/null; then
        echo "安装 curl..."
        sudo apt-get install curl -y
    fi
    if ! command -v jq &> /dev/null; then
        echo "安装 jq..."
        sudo apt-get install jq -y
    fi
    if ! command -v ping &> /dev/null; then
        echo "安装 ping..."
        sudo apt-get install iputils-ping -y
    fi
}

# 获取用户输入
get_user_input() {
    read -p "请输入你的Oracle Cloud API Endpoint: " oracle_endpoint
    read -p "请输入你的Oracle Cloud实例ID: " oracle_instance_id
    read -p "请输入你的Oracle Cloud用户名: " oracle_username
    read -sp "请输入你的Oracle Cloud密码: " oracle_password
    echo
    read -p "请输入你的Cloudflare邮箱: " cloudflare_email
    read -sp "请输入你的Cloudflare API密钥: " cloudflare_api_key
    echo
    read -p "请输入你的Cloudflare Zone ID: " cloudflare_zone_id
    read -p "请输入你想更新的DNS记录ID: " cloudflare_record_id
    read -p "请输入你想更新的域名: " domain_name
}

# 检测IP是否被墙（通过ping）
is_ip_blocked() {
    local ip=$1
    if ping -c 3 $ip &> /dev/null; then
        return 1 # IP未被墙
    else
        return 0 # IP被墙
    fi
}

# 获取Oracle Cloud实例的公共IP
get_oracle_ip() {
    local response=$(curl -s -u ${oracle_username}:${oracle_password} ${oracle_endpoint}/path/to/get/ip)
    public_ip=$(echo $response | jq -r '.public_ip')
    echo $public_ip
}

# 更换Oracle Cloud实例的IP
change_oracle_ip() {
    local response=$(curl -s -X POST -u ${oracle_username}:${oracle_password} ${oracle_endpoint}/path/to/change/ip)
    new_public_ip=$(echo $response | jq -r '.new_public_ip')
    echo $new_public_ip
}

# 更新Cloudflare DNS记录
update_cloudflare_dns() {
    local ip=$1
    local dns_record=$(jq -n \
        --arg type "A" \
        --arg name "$domain_name" \
        --arg content "$ip" \
        --arg ttl 120 \
        '{"type": $type, "name": $name, "content": $content, "ttl": $ttl}')
    curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/${cloudflare_zone_id}/dns_records/${cloudflare_record_id}" \
        -H "X-Auth-Email: ${cloudflare_email}" \
        -H "X-Auth-Key: ${cloudflare_api_key}" \
        -H "Content-Type: application/json" \
        --data "$dns_record"
}

# 主函数
main() {
    install_tools
    get_user_input

    current_ip=$(get_oracle_ip)
    if [[ -z "$current_ip" ]]; then
        echo "无法获取当前IP，脚本终止。"
        exit 1
    fi

    echo "当前IP: $current_ip"

    if is_ip_blocked $current_ip; then
        echo "IP被墙，正在更换IP..."
        new_ip=$(change_oracle_ip)
        if [[ -z "$new_ip" ]]; then
            echo "更换IP失败，脚本终止。"
            exit 1
        fi
        echo "新IP: $new_ip"
        update_cloudflare_dns $new_ip
        echo "Cloudflare DNS记录已更新。"
    else
        echo "IP未被墙，无需更换。"
    fi
}

main
