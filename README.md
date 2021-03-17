# ahk-virtual-desktop-restore

Can save/restore window positions based on title, including their virtual desktop position. Based on and uses [VirtualDesktopAccessor](https://github.com/Ciantic/VirtualDesktopAccessor).

- Download and install DLL from VirtualDesktopAccessor to `C:\Program Files\AutoHotkey\VirtualDesktopAccessor.dll` (or fix reference at top of script)
- Update the function `DefaultWindowLocations()` with your window positions.

## Default shortcuts
- Win+Shift+1 to move to default window positions
  - I suggest setting up your windows, saving them with Win+Shift+2, and then copying the commands into `DefaultWindowLocations()`. 
  - You can then edit the search strings with more generic title terms, e.g. "Slack" instead of the exact title "Slack - MyCorp"
- Win+Shift+2 to save your window positions to the script (saved to `RestoreWindowLocations()`)
- Win+Shift+3 to restore your last save
- Win+Shift+3 to restore your last save
  - Often the default title matches from a direct save won't work without tweaking
- Win+Shift+[ to move current window to the previous desktop
- Win+Shift+] to move current window to the next desktop
- Win+Ctrl+1 to go to desktop 1
- Win+Ctrl+2 to go to desktop 2
