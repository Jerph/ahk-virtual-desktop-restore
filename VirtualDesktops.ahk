#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.

DefaultWindowLocations() {
	global firefoxWindowsMoved
	; Reset status so it can track whether it's activated and set the first tab on each window
	firefoxWindowsMoved := 0

  MoveWindowsToDesktop("Visual Studio Code$", 1, 1152, 0, 1920, 2130) ; Chrome_WidgetWin_1
  MoveWindowsToDesktop("^Slack", 1, 862, 2152, 1936, 1066) ; Chrome_WidgetWin_1
  MoveWindowsToDesktop("Signal", 1, 2885, 616, 782, 646) ; Chrome_WidgetWin_1
  MoveFirefoxWindowsToDesktop("Gmail", 0, 1147, 0, 1930, 2135)
  MoveFirefoxWindowsToDesktop("Boards", 1, 1147, 0, 1930, 2135)
}

RestoreWindowLocations() {
	;begin_locations
	;end_locations
}

; #Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
SetTitleMatchMode, RegEx
; SetTitleMatchMode, 2 ; search can occur anywhere in title

DetectHiddenWindows, On
hwnd:=WinExist("ahk_pid " . DllCall("GetCurrentProcessId","Uint"))
hwnd+=0x1000<<32

hVirtualDesktopAccessor := DllCall("LoadLibrary", Str, "C:\Program Files\AutoHotkey\VirtualDesktopAccessor.dll", "Ptr") 
GoToDesktopNumberProc := DllCall("GetProcAddress", Ptr, hVirtualDesktopAccessor, AStr, "GoToDesktopNumber", "Ptr")
GetCurrentDesktopNumberProc := DllCall("GetProcAddress", Ptr, hVirtualDesktopAccessor, AStr, "GetCurrentDesktopNumber", "Ptr")
IsWindowOnCurrentVirtualDesktopProc := DllCall("GetProcAddress", Ptr, hVirtualDesktopAccessor, AStr, "IsWindowOnCurrentVirtualDesktop", "Ptr")
MoveWindowToDesktopNumberProc := DllCall("GetProcAddress", Ptr, hVirtualDesktopAccessor, AStr, "MoveWindowToDesktopNumber", "Ptr")
RegisterPostMessageHookProc := DllCall("GetProcAddress", Ptr, hVirtualDesktopAccessor, AStr, "RegisterPostMessageHook", "Ptr")
UnregisterPostMessageHookProc := DllCall("GetProcAddress", Ptr, hVirtualDesktopAccessor, AStr, "UnregisterPostMessageHook", "Ptr")
IsPinnedWindowProc := DllCall("GetProcAddress", Ptr, hVirtualDesktopAccessor, AStr, "IsPinnedWindow", "Ptr")
RestartVirtualDesktopAccessorProc := DllCall("GetProcAddress", Ptr, hVirtualDesktopAccessor, AStr, "RestartVirtualDesktopAccessor", "Ptr")
; GetWindowDesktopNumberProc := DllCall("GetProcAddress", Ptr, hVirtualDesktopAccessor, AStr, "GetWindowDesktopNumber", "Ptr")
activeWindowByDesktop := {}
firefoxWindowsMoved := 0

; Restart the virtual desktop accessor when Explorer.exe crashes, or restarts (e.g. when coming from fullscreen game)
explorerRestartMsg := DllCall("user32\RegisterWindowMessage", "Str", "TaskbarCreated")
OnMessage(explorerRestartMsg, "OnExplorerRestart")
OnExplorerRestart(wParam, lParam, msg, hwnd) {
    global RestartVirtualDesktopAccessorProc
    DllCall(RestartVirtualDesktopAccessorProc, UInt, result)
}

MoveCurrentWindowToDesktop(number) {
	global MoveWindowToDesktopNumberProc, GoToDesktopNumberProc, activeWindowByDesktop
	WinGet, activeHwnd, ID, A
	activeWindowByDesktop[number] := 0 ; Do not activate
	DllCall(MoveWindowToDesktopNumberProc, UInt, activeHwnd, UInt, number)
  DllCall(GoToDesktopNumberProc, UInt, number)
}

GoToPrevDesktop() {
	global GetCurrentDesktopNumberProc, GoToDesktopNumberProc
	current := DllCall(GetCurrentDesktopNumberProc, UInt)
	if (current = 0) {
		GoToDesktopNumber(7)
	} else {
		GoToDesktopNumber(current - 1)      
	}
	return
}

GoToNextDesktop() {
	global GetCurrentDesktopNumberProc, GoToDesktopNumberProc
	current := DllCall(GetCurrentDesktopNumberProc, UInt)
	if (current = 7) {
		GoToDesktopNumber(0)
	} else {
		GoToDesktopNumber(current + 1)    
	}
	return
}

GoToDesktopNumber(num) {
	global GetCurrentDesktopNumberProc, GoToDesktopNumberProc, IsPinnedWindowProc, activeWindowByDesktop

	; Store the active window of old desktop, if it is not pinned
	WinGet, activeHwnd, ID, A
	current := DllCall(GetCurrentDesktopNumberProc, UInt) 
	isPinned := DllCall(IsPinnedWindowProc, UInt, activeHwnd)
	if (isPinned == 0) {
		activeWindowByDesktop[current] := activeHwnd
	}

	; Try to avoid flashing task bar buttons, deactivate the current window if it is not pinned
	if (isPinned != 1) {
		WinActivate, ahk_class Shell_TrayWnd
	}

	; Change desktop
	DllCall(GoToDesktopNumberProc, Int, num)
	return
}

; Windows 10 desktop changes listener
DllCall(RegisterPostMessageHookProc, Int, hwnd, Int, 0x1400 + 30)
OnMessage(0x1400 + 30, "VWMess")
VWMess(wParam, lParam, msg, hwnd) {
	global IsWindowOnCurrentVirtualDesktopProc, IsPinnedWindowProc, activeWindowByDesktop

	desktopNumber := lParam + 1
	
	; Try to restore active window from memory (if it's still on the desktop and is not pinned)
	WinGet, activeHwnd, ID, A 
	isPinned := DllCall(IsPinnedWindowProc, UInt, activeHwnd)
	oldHwnd := activeWindowByDesktop[lParam]
	isOnDesktop := DllCall(IsWindowOnCurrentVirtualDesktopProc, UInt, oldHwnd, Int)
	if (isOnDesktop == 1 && isPinned != 1) {
		WinActivate, ahk_id %oldHwnd%
	}

	; Menu, Tray, Icon, Icons/icon%desktopNumber%.ico
	
	; When switching to desktop 1, set background pluto.jpg
	; if (lParam == 0) {
		; DllCall("SystemParametersInfo", UInt, 0x14, UInt, 0, Str, "C:\Users\Jarppa\Pictures\Backgrounds\saturn.jpg", UInt, 1)
	; When switching to desktop 2, set background DeskGmail.png
	; } else if (lParam == 1) {
		; DllCall("SystemParametersInfo", UInt, 0x14, UInt, 0, Str, "C:\Users\Jarppa\Pictures\Backgrounds\DeskGmail.png", UInt, 1)
	; When switching to desktop 7 or 8, set background DeskMisc.png
	; } else if (lParam == 2 || lParam == 3) {
		; DllCall("SystemParametersInfo", UInt, 0x14, UInt, 0, Str, "C:\Users\Jarppa\Pictures\Backgrounds\DeskMisc.png", UInt, 1)
	; Other desktops, set background to DeskWork.png
	; } else {
		; DllCall("SystemParametersInfo", UInt, 0x14, UInt, 0, Str, "C:\Users\Jarppa\Pictures\Backgrounds\DeskWork.png", UInt, 1)
	; }
}

MoveWindowsToDesktop(regex, number, x:="", y:="", width:="", height:="") {
	global MoveWindowToDesktopNumberProc, activeWindowByDesktop

  ; MsgBox, %regex%
	WinGet, id, list,%regex%
	Loop %id%
	{
    this_id := id%A_Index%
    activeWindowByDesktop[number] := 0 ; Do not activate
    DllCall(MoveWindowToDesktopNumberProc, UInt, this_id, UInt, number)
		if (x) {
			WinMove, ahk_id %this_id%, , x, y, width, height
		}
  }
}

; Move Firefox windows whose first tab matches given regex, with " -- Mozilla Firefox" at the end (so /...$/ won't work)
MoveFirefoxWindowsToDesktop(regex, number, x:="", y:="", width:="", height:="") {
	global MoveWindowToDesktopNumberProc, activeWindowByDesktop, firefoxWindowsMoved

  ; MsgBox, %regex%
	WinGet, id, list,Mozilla Firefox$
	Loop %id%
	{
    this_id := id%A_Index%
		if (!firefoxWindowsMoved) {
			WinActivate, ahk_id %this_id%
			Send, ^1
			Sleep, 200 ; wait for the tab to load. If it takes longer than 200ms, it may not work, but you can just run it all again
		}
    WinGetClass, this_class, ahk_id %this_id%
    WinGetTitle, this_title, ahk_id %this_id%
		is_match := RegExMatch(this_title, regex)
    ; MsgBox, 4, , Visiting '%regex%' Windows`n%a_index% of %id%`nahk_id %this_id%`nahk_class %this_class%`n%this_title%`n%is_match%`n`nContinue?
    ; IfMsgBox, NO, break
		if (is_match) {
			activeWindowByDesktop[number] := 0 ; Do not activate
			DllCall(MoveWindowToDesktopNumberProc, UInt, this_id, UInt, number)
			if (x) {
				WinMove, ahk_id %this_id%, , x, y, width, height
			}
		}
  }
	firefoxWindowsMoved := 1
}

SaveWindowLocations() {
	global GetCurrentDesktopNumberProc
	; turn off hidden, make sure to check all desktops
	DetectHiddenWindows, Off
	locations := ""
	; exclusions := "i)(tray|gdi\+|qtool|qwidget|c:\\)"

  ; Loop through each desktop, otherwise non-active desktop windows will be hidden
	cur_dt = 0
  GoToDesktopNumber(cur_dt)
	While(1) {
		GoToDesktopNumber(cur_dt)
		WinGet, id, list,,, Program Manager
		Loop, %id%
		{
				this_id := id%A_Index%
				; WinActivate, ahk_id %this_id%
				WinGetClass, this_class, ahk_id %this_id%
				WinGetTitle, this_title, ahk_id %this_id%
				; MsgBox, 4, , Visiting All Windows`n%a_index% of %id%`nahk_id %this_id%`nahk_class %this_class%`n%this_title%`n`nContinue?
				; IfMsgBox, NO, break
				WinGetPos, this_x, this_y, this_width, this_height, ahk_id %this_id%

				if (this_title) {
					locations := locations . Format("`r`n  MoveWindowsToDesktop(""{}"", {}, {}, {}, {}, {}) `; {}", this_title, cur_dt, this_x, this_y, this_width, this_height, this_class)
				}
		}

    GoToNextDesktop()
		next_dt := DllCall(GetCurrentDesktopNumberProc, UInt)
		if (cur_dt == next_dt || A_Index > 7) {
			break
		}
		cur_dt := next_dt
	}

	file := FileOpen(A_ScriptFullPath, "r")
	code := file.Read()
	file.Close()
	tag := "locations"

	replacement := 
	(
	";begin_{1}
	{2}
	;end_{1}"
	)
	replacement := Format(replacement, tag, locations)
	replaced := RegExReplace(code, Format("s);begin_{1}.*;end_{1}", tag), replacement)
	file := FileOpen(A_ScriptFullPath, "w")
	file.Write(replaced)
	file.Close()
	DetectHiddenWindows, On
}

; Switching desktops:
; Win + Ctrl + 1 = Switch to desktop 1
^#1::GoToDesktopNumber(0)

; Win + Ctrl + 2 = Switch to desktop 2
^#2::GoToDesktopNumber(1)

; Moving windowes:
; Win + Shift + 1 = Move current window to desktop 1, and go there
+#[::MoveCurrentWindowToDesktop(0)

+#]::MoveCurrentWindowToDesktop(1)

+#1::DefaultWindowLocations()

+#2::SaveWindowLocations()

+#3::RestoreWindowLocations()