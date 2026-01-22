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
