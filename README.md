# Aliyun_DDNS_Script
阿里云ddns使用shell实现脚本简单易用

使用方法：
建议提前安装jq  （yum install jq -y）
修改以下4项配置即可直接再在linux使用
AccessKeyId="你的AccessKeyId"
AccessKeySecret="你的AccessKeySecret"
DomainName="你的域名 示例：baidu.com"
RR="你的子域名 示例：www"

修改后可以写入crontab定时执行
* * * * *	/root/ddns.sh  #每分钟执行一次
