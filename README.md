# ssh-x11-forwarding-guide
使用ssh远程连接+端口转发实现远程弹窗本地化显示
配置ssh密钥和xlaunch端口转发
===
说明: 在使用虚拟机进行开发和测试时,因为远程环境不允许或者卡顿,建议使用ssh进行远程访问,实现远程开发
- 问题1
```
使用ssh登录时,在vscode界面下需要每次输入密码,令人十分烦恼,通过配置ssh密钥的方式实现同一ip免密登录
```
- 问题2
```
由于win界面下使用vscode测试时,弹出的窗口并不会显示在win界面下,导致开发困难,
利用xlaunch实现端口转发,将窗口转发至Windows界面
```
## 1）虚拟机端：安装并开启 SSH + X11 转发所需组件

- 在虚拟机终端执行：
```
sudo apt update
sudo apt install -y openssh-server xauth x11-apps
sudo systemctl enable --now ssh
sudo systemctl status ssh --no-pager
```
- 然后编辑 sshd 配置：
```
sudo nano /etc/ssh/sshd_config
```

- 确保下面这些项存在且为（没有就加上，有就改成这样）：
```
PubkeyAuthentication yes
X11Forwarding yes
X11UseLocalhost yes
AllowTcpForwarding yes
```

- 重启 ssh 服务：
```
sudo systemctl restart ssh
```

## 2）Windows 端：生成 SSH 密钥（推荐 ed25519）

- 在 Windows PowerShell 执行：
```
ssh-keygen -t ed25519 -f $env:USERPROFILE\.ssh\id_ed25519
```

- 一路回车即可；

## 3）把公钥放进虚拟机：实现免密登录
- 用一条命令把公钥追加到虚拟机 authorized_keys

把下面命令里的 USER 和 VM_IP 换成你的：
```
type $env:USERPROFILE\.ssh\id_ed25519.pub | ssh USER@VM_IP "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```
- 虚拟机上修权限（很关键）

登录到虚拟机执行：
```
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
```

## 4）配置 SSH 客户端：一条命令带 X11 转发登录

- 确保能免密登录：

```
ssh USER@VM_IP
```

- 没问题后，退出（exit），然后用 X11 转发登录：
```
ssh -Y USER@VM_IP
```
-Y 比 -X 更“可信转发”，很多 GUI 程序（尤其是复杂的）更稳；如果你很在意安全可换 -X。

## 5）Windows 端：启动 XLaunch
- 安装xlaunch

  [xlaunch](https://sourceforge.net/projects/vcxsrv/)

- 安装后,使用默认设置

仅需勾选
✅ Disable access control
## 6) 配置环境变量DISPLAY
验证当前终端,当前用户,当前机器
```
echo $env:DISPLAY
[Environment]::GetEnvironmentVariable("DISPLAY","User")
[Environment]::GetEnvironmentVariable("DISPLAY","Machine")
```
如果没有值,使用下列命令为当前终端设置
```
$env:DISPLAY="127.0.0.1:0.0"
```
（有的人用 localhost:0.0 也行，127.0.0.1 更稳。）

如果你希望以后每次打开 PowerShell 都自动有 DISPLAY，可以再加一条（永久写入用户环境变量）,新建终端生效：
```
setx DISPLAY "127.0.0.1:0.0"
```

## 6）验证：让虚拟机弹窗出现在 Windows 桌面
新建一个终端
```
ssh -Y USER@VM_IP
```
确保你现在是 ssh -Y 连接进去的虚拟机终端(启动xlaunch后连接)，然后执行：
```
echo $DISPLAY
xclock
```
## 7）编写 SSH 配置，便于无参数登录(ssh vm_ip)
- 在 Windows 创建/编辑：
```
C:\Users\<你>\.ssh\config
```
写入（替换VM_IP）：
```
Host vm_ip
  HostName vm_ip
  User chiway
  ForwardX11 yes
  ForwardX11Trusted yes
```

以后直接：
```
ssh vm_ip
```

## 8) 实现弹窗始终出现在顶端(不会随着点击而下沉)
- 安装autohotkey v2 自动执行脚本

  [autohotkey v2](https://www.autohotkey.com/)
  
- 安装完之后，右键桌面 → 新建 → 文本文档，重命名为
```
xlaunch_always_on_top.ahk
（后缀一定要是 .ahk）
```
- 使用记事本打开,替换掉所有
```
#Requires AutoHotkey v2.0
; 每 1 秒检查一次，但只给“还没置顶”的 vcxsrv 窗口加置顶
SetTimer PinXWin, 1000

PinXWin() {
    ; 遍历所有 vcxsrv.exe 的窗口
    for hwnd in WinGetList("ahk_exe vcxsrv.exe") {
        try {
            ; 读取扩展样式，0x00000008 对应 WS_EX_TOPMOST（置顶标志）
            exStyle := WinGetExStyle(hwnd)
            ; 如果当前窗口还不是置顶，再设置一次
            if !(exStyle & 0x00000008) {
                WinSetAlwaysOnTop 1, hwnd
            }
        }
    }
}

```

## 9) 实现开机自启
- win + R 打开运行
```
shell:startup
```
打开开始文件夹
- 放入xlaunch 快捷方式
- 放入写好的xlaunch_always_on_top.ahk脚本文件

---
到此为止该教程结束,祝各位开发者一路顺风,有任何问题欢迎讨论

                                              -- Chiway Luo


