--[[ 
Genre Profiles Patch for KOReader
Automatically applies KOReader profiles based on book's genre tag.
Works with the genre-badges patch and reads from profiles.lua.
]]

local userpatch = require("userpatch")
local logger = require("logger")

-- stylua: ignore start
--========================== Genre to Profile Mapping ================================
local genre_to_profile = {
    technical = "Deep Study",
    philosophy = "Contemplative",
    scifi = "Immersion",
    novels = "Classic Paperback",
    code = "Code Reader",
}
--====================================================================================
-- stylua: ignore end

local function getGenreTag(file_path)
    local DocSettings = require("docsettings")
    if not file_path then return nil end
    local doc_settings = DocSettings:open(file_path)
    if doc_settings then
        return doc_settings:readSetting("genre_tag")
    end
    return nil
end

local function patchGenreProfiles()
    local ReaderUI = require("apps/reader/readerui")
    
    if ReaderUI.patched_genre_profiles then
        return
    end
    ReaderUI.patched_genre_profiles = true
    
    local orig_ReaderUI_init = ReaderUI.init
    
    function ReaderUI:init(...)
        orig_ReaderUI_init(self, ...)
        
        local file_path = self.document and self.document.file
        if not file_path then return end
        
        local genre = getGenreTag(file_path)
        if not genre then return end
        
        local profile_name = genre_to_profile[genre]
        if not profile_name then return end
        
        local UIManager = require("ui/uimanager")
        UIManager:scheduleIn(0.5, function()
            local profiles_plugin = self:findModuleByName("profiles")
            if profiles_plugin then
                profiles_plugin:onProfileExecute(profile_name, { qm_show = false })
                logger.info("Genre Profiles: Applied '" .. profile_name .. "' profile for genre '" .. genre .. "'")
                
                local Notification = require("ui/widget/notification")
                UIManager:show(Notification:new{
                    text = "Profile: " .. profile_name,
                    timeout = 2,
                })
            else
                logger.warn("Genre Profiles: Could not find profiles plugin")
            end
        end)
    end
    
    logger.info("Genre Profiles patch loaded successfully")
end

patchGenreProfiles()
