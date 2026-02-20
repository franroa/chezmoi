--[[ 
Genre Badges Patch for KOReader
Displays genre-specific badges and colored borders on book covers.
Detects genre from book metadata or manual tagging.
]]

local Blitbuffer = require("ffi/blitbuffer")
local Device = require("device")
local Screen = Device.screen
local userpatch = require("userpatch")
local logger = require("logger")

-- stylua: ignore start
--========================== Edit your preferences here ================================
local badge_position = "top-left"       -- "top-left", "top-right", "bottom-left", "bottom-right"
local badge_size = Screen:scaleBySize(28)
local badge_margin = Screen:scaleBySize(4)
local border_width = Screen:scaleBySize(2)
local show_border = false
local show_badge = true

local genre_config = {
    scifi = {
        keywords = { "science fiction", "sci-fi", "scifi", "sf", "space", "cyberpunk", "dystopia", "alien" },
        icon = "genre.scifi",
        border_color = "#00BFFF",  -- Cyan/Deep Sky Blue
    },
    technical = {
        keywords = { "technical", "programming", "computer", "engineering", "science", "mathematics", "textbook", "manual", "reference" },
        icon = "genre.technical",
        border_color = "#FF8C00",  -- Dark Orange
    },
    philosophy = {
        keywords = { "philosophy", "spiritual", "spirituality", "religion", "meditation", "mindfulness", "buddhism", "stoicism", "metaphysics", "ethics", "wisdom" },
        icon = "genre.philosophy",
        border_color = "#DAA520",  -- Goldenrod
    },
    novels = {
        keywords = { "fiction", "novel", "romance", "thriller", "mystery", "adventure", "drama", "literary", "classic" },
        icon = "genre.novels",
        border_color = "#8B0000",  -- Dark Red/Burgundy
    },
    code = {
        keywords = { "programming", "coding", "software", "developer", "javascript", "python", "java", "code", "algorithm" },
        icon = "genre.technical",
        border_color = "#32CD32",  -- Lime Green
    },
}
--======================================================================================
-- stylua: ignore end

local genre_colors = {}
for genre, config in pairs(genre_config) do
    genre_colors[genre] = Blitbuffer.colorFromString(config.border_color)
end

local function detectGenreFromMetadata(bookinfo)
    if not bookinfo then return nil end
    
    local genre_field = bookinfo.genre or bookinfo.subjects or bookinfo.tags or ""
    if type(genre_field) == "table" then
        genre_field = table.concat(genre_field, " ")
    end
    genre_field = genre_field:lower()
    
    for genre, config in pairs(genre_config) do
        for _, keyword in ipairs(config.keywords) do
            if genre_field:find(keyword, 1, true) then
                return genre
            end
        end
    end
    return nil
end

local function getManualGenre(file_path)
    local DocSettings = require("docsettings")
    if not file_path then return nil end
    local doc_settings = DocSettings:open(file_path)
    if doc_settings then
        return doc_settings:readSetting("genre_tag")
    end
    return nil
end

local function setManualGenre(file_path, genre)
    local DocSettings = require("docsettings")
    if not file_path then return end
    local doc_settings = DocSettings:open(file_path)
    if doc_settings then
        doc_settings:saveSetting("genre_tag", genre)
        doc_settings:flush()
    end
end

local function patchGenreBadges(plugin)
    local IconWidget = require("ui/widget/iconwidget")
    local MosaicMenu = require("mosaicmenu")
    local MosaicMenuItem = userpatch.getUpValue(MosaicMenu._updateItemsBuildUI, "MosaicMenuItem")
    local BookInfoManager = require("bookinfomanager")

    if not MosaicMenuItem then
        logger.warn("Genre Badges: Could not find MosaicMenuItem")
        return
    end

    if MosaicMenuItem.patched_genre_badges then
        return
    end
    MosaicMenuItem.patched_genre_badges = true

    local genre_icons = {}
    for genre, config in pairs(genre_config) do
        local icon = IconWidget:new({ icon = config.icon, width = badge_size, height = badge_size, alpha = true })
        if icon then
            genre_icons[genre] = icon
        else
            logger.warn("Genre Badges: Failed to load icon for " .. genre)
        end
    end

    local orig_MosaicMenuItem_paintTo = MosaicMenuItem.paintTo

    function MosaicMenuItem:paintTo(bb, x, y)
        orig_MosaicMenuItem_paintTo(self, bb, x, y)

        if self.is_directory or not self.filepath then
            return
        end

        local target = self[1] and self[1][1] and self[1][1][1]
        if not target or not target.dimen then
            return
        end

        local genre = getManualGenre(self.filepath)
        
        if not genre then
            local bookinfo = BookInfoManager:getBookInfo(self.filepath, true)
            genre = detectGenreFromMetadata(bookinfo)
        end

        if not genre then
            return
        end

        local fx = x + math.floor((self.width - target.dimen.w) / 2)
        local fy = y + math.floor((self.height - target.dimen.h) / 2)
        local fw, fh = target.dimen.w, target.dimen.h

        if show_border and genre_colors[genre] then
            local pad = target.padding or 0
            local ix = fx + pad
            local iy = fy + pad
            local iw = fw - 2 * pad
            local ih = fh - 2 * pad
            
            bb:paintRect(ix, iy, iw, border_width, genre_colors[genre])
            bb:paintRect(ix, iy, border_width, ih, genre_colors[genre])
            bb:paintRect(ix + iw - border_width, iy, border_width, ih, genre_colors[genre])
            bb:paintRect(ix, iy + ih - border_width, iw, border_width, genre_colors[genre])
        end

        if show_badge and genre_icons[genre] then
            local icon = genre_icons[genre]
            local icon_x, icon_y

            if badge_position == "top-right" then
                icon_x = fx + fw - badge_size - badge_margin
                icon_y = fy + badge_margin
            elseif badge_position == "top-left" then
                icon_x = fx + badge_margin
                icon_y = fy + badge_margin
            elseif badge_position == "bottom-right" then
                icon_x = fx + fw - badge_size - badge_margin
                icon_y = fy + fh - badge_size - badge_margin
            elseif badge_position == "bottom-left" then
                icon_x = fx + badge_margin
                icon_y = fy + fh - badge_size - badge_margin
            end

            icon:paintTo(bb, icon_x, icon_y)
        end
    end

    local FileManager = require("apps/filemanager/filemanager")
    local UIManager = require("ui/uimanager")
    local ButtonDialog = require("ui/widget/buttondialog")
    local _ = require("gettext")

    local function showGenreDialog(file)
        local current_genre = getManualGenre(file)
        local dialog
        dialog = ButtonDialog:new{
            title = _("Set Book Genre"),
            buttons = {
                {
                    {
                        text = current_genre == "scifi" and "✓ Sci-Fi" or "Sci-Fi",
                        callback = function()
                            setManualGenre(file, "scifi")
                            UIManager:close(dialog)
                            local menu = FileManager.getMenuInstance()
                            if menu then
                                UIManager:close(menu.file_dialog)
                                menu:updateItems(1, true)
                            end
                        end,
                    },
                    {
                        text = current_genre == "technical" and "✓ Technical" or "Technical",
                        callback = function()
                            setManualGenre(file, "technical")
                            UIManager:close(dialog)
                            local menu = FileManager.getMenuInstance()
                            if menu then
                                UIManager:close(menu.file_dialog)
                                menu:updateItems(1, true)
                            end
                        end,
                    },
                },
                {
                    {
                        text = current_genre == "philosophy" and "✓ Philosophy" or "Philosophy",
                        callback = function()
                            setManualGenre(file, "philosophy")
                            UIManager:close(dialog)
                            local menu = FileManager.getMenuInstance()
                            if menu then
                                UIManager:close(menu.file_dialog)
                                menu:updateItems(1, true)
                            end
                        end,
                    },
                    {
                        text = current_genre == "novels" and "✓ Novels" or "Novels",
                        callback = function()
                            setManualGenre(file, "novels")
                            UIManager:close(dialog)
                            local menu = FileManager.getMenuInstance()
                            if menu then
                                UIManager:close(menu.file_dialog)
                                menu:updateItems(1, true)
                            end
                        end,
                    },
                },
                {
                    {
                        text = current_genre == "code" and "✓ Code" or "Code",
                        callback = function()
                            setManualGenre(file, "code")
                            UIManager:close(dialog)
                            local menu = FileManager.getMenuInstance()
                            if menu then
                                UIManager:close(menu.file_dialog)
                                menu:updateItems(1, true)
                            end
                        end,
                    },
                    {
                        text = _("Clear"),
                        callback = function()
                            setManualGenre(file, nil)
                            UIManager:close(dialog)
                            local menu = FileManager.getMenuInstance()
                            if menu then
                                UIManager:close(menu.file_dialog)
                                menu:updateItems(1, true)
                            end
                        end,
                    },
                },
                {
                    {
                        text = _("Cancel"),
                        callback = function()
                            UIManager:close(dialog)
                        end,
                    },
                },
            },
        }
        UIManager:show(dialog)
    end

    FileManager.addFileDialogButtons(FileManager, "genre_badges", function(file, is_file)
        if is_file then
            local current_genre = getManualGenre(file)
            local genre_text = current_genre and (" [" .. current_genre .. "]") or ""
            return {
                {
                    text = _("Set genre") .. genre_text,
                    callback = function()
                        local menu = FileManager.getMenuInstance()
                        if menu then
                            UIManager:close(menu.file_dialog)
                        end
                        showGenreDialog(file)
                    end,
                },
            }
        end
    end)

    logger.info("Genre Badges patch applied successfully")
end

userpatch.registerPatchPluginFunc("coverbrowser", patchGenreBadges)
