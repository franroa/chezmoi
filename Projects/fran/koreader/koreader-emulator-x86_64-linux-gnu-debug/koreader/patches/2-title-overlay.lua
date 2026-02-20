--[[ 
User patch for KOReader to show book title overlay on cover in mosaic view.
Long-press a book to toggle "Show title on cover" for that specific book.
]]
--

-- stylua: ignore start
--========================== [[Edit your preferences here]] ================================
local title_font_face = "cfont"     -- Font face: "cfont" (default), "tfont", "infofont", "smallinfofont", etc.
local title_font_size = 14          -- Font size for the title text
local title_font_bold = true        -- Bold text: true or false
local title_alpha = 1.0             -- Transparency of the background (0-1)
local title_padding = 6             -- Padding around the title text
local title_max_lines = 3           -- Maximum lines for the title
local title_position = "bottom"     -- Position: "top", "center", or "bottom"
local title_bg_color = "#F5F0E6"    -- Library: warm cream paper
local title_fg_color = "#2B2B2B"    -- Library: soft black ink
--==========================================================================================
-- stylua: ignore end

local userpatch = require("userpatch")

local function patchTitleOverlay(plugin)
    local AlphaContainer = require("ui/widget/container/alphacontainer")
    local BD = require("ui/bidi")
    local Blitbuffer = require("ffi/blitbuffer")
    local Font = require("ui/font")
    local FrameContainer = require("ui/widget/container/framecontainer")
    local MosaicMenu = require("mosaicmenu")
    local TextBoxWidget = require("ui/widget/textboxwidget")
    local Screen = require("device").screen
    local logger = require("logger")
    local _ = require("gettext")
    local FileManager = require("apps/filemanager/filemanager")

    local MosaicMenuItem = userpatch.getUpValue(MosaicMenu._updateItemsBuildUI, "MosaicMenuItem")

    if not MosaicMenuItem then
        logger.warn("Could not find MosaicMenuItem - title overlay patch not applied")
        return
    end

    if MosaicMenuItem.patched_title_overlay then
        return
    end
    MosaicMenuItem.patched_title_overlay = true

    local BookInfoManager = userpatch.getUpValue(MosaicMenuItem.update, "BookInfoManager")

    local function invertHexColor(hex)
        local r = tonumber(hex:sub(2, 3), 16)
        local g = tonumber(hex:sub(4, 5), 16)
        local b = tonumber(hex:sub(6, 7), 16)
        if not r or not g or not b then return hex end
        return string.format("#%02X%02X%02X", 255 - r, 255 - g, 255 - b)
    end

    -- Convert RGB hex to grayscale value (0-255) using luminance formula
    local function hexToGrayscale(hex)
        local r = tonumber(hex:sub(2, 3), 16) or 255
        local g = tonumber(hex:sub(4, 5), 16) or 255
        local b = tonumber(hex:sub(6, 7), 16) or 255
        return math.floor(0.299 * r + 0.587 * g + 0.114 * b)
    end

    -- Get the UI background color as grayscale (avoids BGR buffer issues)
    local function getUiBgGrayscale()
        local hex = G_reader_settings:readSetting("ui_background_color_hex", "#ffffff")
        local invert_in_night = G_reader_settings:isTrue("ui_background_color_inverted")
        local night_mode = G_reader_settings:isTrue("night_mode")
        if night_mode and not invert_in_night then
            hex = invertHexColor(hex)
        end
        local gray = hexToGrayscale(hex)
        return Blitbuffer.Color8(gray)
    end

    local function getBgColor()
        if title_bg_color == "auto" then
            return getUiBgGrayscale()
        elseif title_bg_color == "transparent" then
            return nil
        elseif title_bg_color == "black" then
            return Blitbuffer.COLOR_BLACK
        elseif title_bg_color == "white" then
            return Blitbuffer.COLOR_WHITE
        elseif title_bg_color:match("^#%x%x%x%x?%x?%x?$") then
            local gray = hexToGrayscale(title_bg_color)
            return Blitbuffer.Color8(gray)
        else
            return Blitbuffer.COLOR_WHITE
        end
    end

    local function getFgColor()
        if title_fg_color == "auto" then
            local gray = 255 - hexToGrayscale(G_reader_settings:readSetting("ui_background_color_hex", "#ffffff"))
            local invert_in_night = G_reader_settings:isTrue("ui_background_color_inverted")
            local night_mode = G_reader_settings:isTrue("night_mode")
            if night_mode and not invert_in_night then
                gray = 255 - gray
            end
            return Blitbuffer.Color8(gray)
        elseif title_fg_color == "white" then
            return Blitbuffer.COLOR_WHITE
        elseif title_fg_color == "black" then
            return Blitbuffer.COLOR_BLACK
        elseif title_fg_color:match("^#%x%x%x%x?%x?%x?$") then
            local gray = hexToGrayscale(title_fg_color)
            return Blitbuffer.Color8(gray)
        else
            return Blitbuffer.COLOR_BLACK
        end
    end

    local function getSettingKey(filepath)
        return "title_overlay:" .. filepath
    end

    local function shouldShowTitle(filepath)
        if not filepath then return false end
        return BookInfoManager:getSetting(getSettingKey(filepath))
    end

    local function setShowTitle(filepath, value)
        BookInfoManager:saveSetting(getSettingKey(filepath), value)
    end

    local orig_MosaicMenuItem_paint = MosaicMenuItem.paintTo

    function MosaicMenuItem:paintTo(bb, x, y)
        orig_MosaicMenuItem_paint(self, bb, x, y)

        if self.is_directory then
            return
        end

        if not shouldShowTitle(self.filepath) then
            return
        end

        local target = self[1][1][1]
        if not target or not target.dimen then
            return
        end

        local title_text = nil
        if self.filepath then
            local bookinfo = BookInfoManager:getBookInfo(self.filepath, false)
            if bookinfo and bookinfo.title then
                title_text = bookinfo.title
            end
        end
        if not title_text then
            title_text = self.text
        end
        if not title_text or title_text == "" then
            return
        end

        title_text = BD.auto(title_text)

        local fx = x + math.floor((self.width - target.dimen.w) / 2)
        local fy = y + math.floor((self.height - target.dimen.h) / 2)
        local fw, fh = target.dimen.w, target.dimen.h

        local pad = target.padding or 0
        local inner_w = fw - 2 * pad
        local inner_h = fh - 2 * pad

        local scaled_font_size = Screen:scaleBySize(title_font_size)

        local bg_color = getBgColor()
        local fg_color = getFgColor()

        -- Use grayscale colors and exclude from bg_color hook to avoid BGR buffer issues
        -- TextBoxWidget spans full width, no FrameContainer
        local title_widget = TextBoxWidget:new({
            text = title_text,
            face = Font:getFace(title_font_face, scaled_font_size),
            width = inner_w,
            alignment = "center",
            bold = title_font_bold,
            fgcolor = fg_color,
            bgcolor = bg_color,
            exclude_bg_color_hook = true,
        })

        local line_height = title_widget:getLineHeight()
        local max_height = line_height * title_max_lines
        local title_size = title_widget:getSize()
        if title_size.h > max_height then
            title_widget:free()
            title_widget = TextBoxWidget:new({
                text = title_text,
                face = Font:getFace(title_font_face, scaled_font_size),
                width = inner_w,
                height = max_height,
                height_adjust = true,
                height_overflow_show_ellipsis = true,
                alignment = "center",
                bold = title_font_bold,
                fgcolor = fg_color,
                bgcolor = bg_color,
                exclude_bg_color_hook = true,
            })
        end

        local overlay_widget
        if bg_color then
            overlay_widget = AlphaContainer:new({
                alpha = title_alpha,
                title_widget,
            })
        else
            overlay_widget = title_widget
        end

        local overlay_size = overlay_widget:getSize()
        local draw_x = fx + pad
        local draw_y

        if title_position == "top" then
            draw_y = fy + pad
        elseif title_position == "center" then
            draw_y = fy + pad + math.floor((inner_h - overlay_size.h) / 2)
        else
            draw_y = fy + pad + inner_h - overlay_size.h
        end

        overlay_widget:paintTo(bb, math.floor(draw_x), math.floor(draw_y))
        overlay_widget:free()
    end

    FileManager.addFileDialogButtons(FileManager, "title_overlay", function(file, is_file, bookinfo)
        if is_file then
            local show_title = shouldShowTitle(file)
            return {
                {
                    text = show_title and _("Hide title on cover") or _("Show title on cover"),
                    callback = function()
                        setShowTitle(file, not show_title)
                        FileManager.files_updated = true
                        local menu = FileManager.getMenuInstance()
                        if menu then
                            local UIManager = require("ui/uimanager")
                            UIManager:close(menu.file_dialog)
                            menu:updateItems(1, true)
                        end
                    end,
                },
            }
        end
    end)
end

userpatch.registerPatchPluginFunc("coverbrowser", patchTitleOverlay)
