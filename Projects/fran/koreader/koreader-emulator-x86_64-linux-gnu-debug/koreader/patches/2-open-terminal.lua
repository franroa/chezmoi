local UIManager = require("ui/uimanager")
local InfoMessage = require("ui/widget/infomessage")
local Device = require("device")

if Device:isAndroid() then
    local android = require("android")
    
    UIManager:show(InfoMessage:new{
        text = "Trying to open Android 15 Terminal...",
        timeout = 2,
    })
    
    android.openLink("android-app://com.android.virtualization.terminal")
    
    local orig_quit = UIManager.quit
    UIManager.quit = function(self, exit_code, implicit)
        UIManager:show(InfoMessage:new{
            text = "Please close the Terminal app manually.",
            timeout = 3,
        })
        UIManager:forceRePaint()
        local ffi = require("ffi")
        ffi.C.sleep(3)
        return orig_quit(self, exit_code, implicit)
    end
end
