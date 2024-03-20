#!/bin/bash
#Time:20240320
# 阿里云API的相关配置
AccessKeyId="你的AccessKeyId"
AccessKeySecret="你的AccessKeySecret"
DomainName="你的域名 示例：baidu.com"
RR="你的子域名 示例：www"
Type="A"

# 阿里云API的公共参数
Format="json"
Version="2015-01-09"
SignatureMethod="HMAC-SHA1"
SignatureVersion="1.0"
# 获取当前公网IP
PublicIP=$(curl -s http://ifconfig.me)

# URL编码函数
urlencode() {
    local old_lc_collate=$LC_COLLATE
    LC_COLLATE=C
    local length="${#1}"
    for (( i = 0; i < length; i++ )); do
        local c="${1:i:1}"
        case $c in
            [a-zA-Z0-9.~_-]) printf "$c" ;;
            *) printf '%%%02X' "'$c" ;;
        esac
    done
    LC_COLLATE=$old_lc_collate
}

# 生成签名
generate_signature() {
    local QueryString=$1
    # 构造签名字符串
    local StringToSign="GET&%2F&$(urlencode "$QueryString")"
    # 生成签名
    local Signature=$(echo -n "$StringToSign" | openssl dgst -sha1 -hmac "$AccessKeySecret&" -binary | base64)
    # 对签名进行URL编码
    echo $(urlencode "$Signature")
}

# 发送请求
send_request() {
    local QueryString=$1
    local Signature=$(generate_signature "$QueryString")
    local URL="https://alidns.aliyuncs.com/?$QueryString&Signature=$Signature"
	#echo "完整URL：$URL"
    local Response=$(curl -s "$URL")
	#返回请求体
    echo "$Response"
}

# 获取DNS记录ID和当前记录的IP
get_record_info() {
    local Timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local SignatureNonce=$(uuidgen)
	local QueryString="AccessKeyId=$(urlencode "$AccessKeyId")&Action=DescribeDomainRecords&DomainName=$(urlencode "$DomainName")&Format=$(urlencode "$Format")&SignatureMethod=$(urlencode "$SignatureMethod")&SignatureNonce=$(urlencode "$SignatureNonce")&SignatureVersion=$(urlencode "$SignatureVersion")&Timestamp=$(urlencode "$Timestamp")&Version=$(urlencode "$Version")"
    local Response=$(send_request "$QueryString")
    local RecordId=$(echo $Response | jq -r ".DomainRecords.Record[] | select(.RR==\"$RR\" and .Type==\"$Type\").RecordId")
    local RecordIP=$(echo $Response | jq -r ".DomainRecords.Record[] | select(.RR==\"$RR\" and .Type==\"$Type\").Value")

    echo $RecordId $RecordIP
}

# 更新DNS记录
update_record() {
    local RecordId=$1
    local Value=$2
	local Timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local SignatureNonce=$(uuidgen)
    local QueryString="AccessKeyId=$(urlencode "$AccessKeyId")&Action=UpdateDomainRecord&Format=$(urlencode "$Format")&RR=$(urlencode "$RR")&RecordId=$(urlencode "$RecordId")&SignatureMethod=$(urlencode "$SignatureMethod")&SignatureNonce=$(urlencode "$SignatureNonce")&SignatureVersion=$(urlencode "$SignatureVersion")&Timestamp=$(urlencode "$Timestamp")&Type=$(urlencode "$Type")&Value=$(urlencode "$Value")&Version=$(urlencode "$Version")"
	local Response=$(send_request "$QueryString")
    echo $Response
}

# 主逻辑
main() {
    local RecordInfo=($(get_record_info))
    local RecordId=${RecordInfo[0]}
	echo "当前解析ID：$RecordId"
    local RecordIP=${RecordInfo[1]}
	echo "当前解析IP：$RecordIP"
    if [ "$RecordIP" != "$PublicIP" ]; then
        echo "当前DNS解析IP:($RecordIP) 与公网IP:($PublicIP)不同，执行更新DNS记录..."
        local UpdateResponse=$(update_record "$RecordId" "$PublicIP")
		echo "Update response: $UpdateResponse"
    else
        echo "当前DNS解析IP：($RecordIP) 与公网IP相同 ($PublicIP)，无需更新。"
    fi
}

# 执行主逻辑
main >temp.log
echo "当前时间：`date`" >>temp.log
