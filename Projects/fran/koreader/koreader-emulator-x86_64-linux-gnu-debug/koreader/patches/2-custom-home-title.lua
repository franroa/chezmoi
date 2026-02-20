--[[
User patch to customize the home screen title.
Change the title below to whatever you prefer.
]]

-- stylua: ignore start
--============================ [[Edit your preferences here]] =============================
local custom_title = "Fran´s Reader"  -- <-- Change this to your desired title
local custom_subtitle = "Best Books In Chinatown"    -- <-- Empty to hide path, or set a custom string
--========================================================================================
-- stylua: ignore end

local FileManager = require("apps/filemanager/filemanager")

FileManager.title = custom_title

FileManager.updateTitleBarPath = function(self)
    self.title_bar:setSubTitle(custom_subtitle)
end
FileManager.onPathChanged = FileManager.updateTitleBarPath
