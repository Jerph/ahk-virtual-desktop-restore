# ahk-virtual-desktop-restore

Based on and using [VirtualDesktopAccessor](https://github.com/Ciantic/VirtualDesktopAccessor):

- Download and install DLL from VirtualDesktopAccessor to `C:\Program Files\AutoHotkey\VirtualDesktopAccessor.dll` (or fix reference at top of script)
- Use Ctrl+Win+2 to save your window positions to the script
- Use Ctrl+Win+3 to restore your last save
- Update the function DefaultWindowLocations and use Ctrl+Win+1 to move to default window positions
  - I suggest setting up your windows, saving them, and then copying them to DefaultWindowLocations. 
  - You can then edit the search strings with more generic words like "Slack" instead of the exact titles
