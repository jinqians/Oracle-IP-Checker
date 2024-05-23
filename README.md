# Oracle_ip_checker.sh
自动检测oracle cloud IP是否被ban，自动更换IP，并同步到cloudflare

## 改脚本需部署到国内服务器上

## 使用方法

### 赋予执行权限:
在终端中运行以下命令赋予脚本执行权限：
```sh
chmod +x Oracle_ip_checker.sh
```
### 运行脚本:
运行脚本时会提示输入必要的配置项：
```sh
Oracle_ip_checker.sh
```

### 设置定时任务
输入 `crontab -e` 并按下回车键，这会打开当前用户的 crontab 文件进行编辑
```sh
* * * * * /path/to/Oracle_ip_checker.sh>> /path/to/logfile.log 2>&1

```
