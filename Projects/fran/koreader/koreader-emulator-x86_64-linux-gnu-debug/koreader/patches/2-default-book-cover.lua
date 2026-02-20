--[[ 
User patch for KOReader to show a default cover icon when a book does not have a cover.
Maintains the same frame width and aspect ratio as books with covers.
Shows the book title using the title overlay system for books without covers.
]]
--

-- stylua: ignore start
--========================== [[Edit your preferences here]] ================================
local aspect_ratio = 2 / 3          -- Aspect ratio matching other book covers (width/height)
local icon_scale = 0.35             -- Scale of the book icon relative to cover size (0.1 to 0.6)
local bg_color = "#F5F0E6"          -- Library: warm cream paper
local title_font_face = "cfont"     -- Font face: "cfont" (default), "tfont", "infofont", "smallinfofont", etc.
local title_font_size = 14          -- Font size for the title text
local title_font_bold = true        -- Bold text: true or false
local title_alpha = 1.0             -- Transparency of the title background (0-1)
local title_padding = 6             -- Padding around the title text
local title_max_lines = 3           -- Maximum lines for the title
local title_position = "bottom"     -- Position: "top", "center", or "bottom"
local title_bg_color = "#F5F0E6"    -- Library: warm cream paper
local title_fg_color = "#2B2B2B"    -- Library: soft black ink
local frame_border_size = 1         -- Border thickness around the default cover
--==========================================================================================
-- stylua: ignore end

local userpatch = require("userpatch")

local function patchDefaultCover(plugin)
    local AlphaContainer = require("ui/widget/container/alphacontainer")
    local BD = require("ui/bidi")
    local Blitbuffer = require("ffi/blitbuffer")
    local CenterContainer = require("ui/widget/container/centercontainer")
    local Device = require("device")
    local Font = require("ui/font")
    local FrameContainer = require("ui/widget/container/framecontainer")
    local Geom = require("ui/geometry")
    local IconWidget = require("ui/widget/iconwidget")
    local MosaicMenu = require("mosaicmenu")
    local OverlapGroup = require("ui/widget/overlapgroup")
    local TextBoxWidget = require("ui/widget/textboxwidget")
    local logger = require("logger")
    local Screen = Device.screen
    local _ = require("gettext")

    local MosaicMenuItem = userpatch.getUpValue(MosaicMenu._updateItemsBuildUI, "MosaicMenuItem")

    if not MosaicMenuItem then
        logger.warn("Could not find MosaicMenuItem - default cover patch not applied")
        return
    end

    if MosaicMenuItem.patched_default_cover then
        return
    end
    MosaicMenuItem.patched_default_cover = true

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

    local function getBgColor()
        if bg_color == "auto" then
            local hex = G_reader_settings:readSetting("ui_background_color_hex", "#ffffff")
            local invert_in_night = G_reader_settings:isTrue("ui_background_color_inverted")
            local night_mode = G_reader_settings:isTrue("night_mode")
            if night_mode and not invert_in_night then
                hex = invertHexColor(hex)
            end
            local gray = hexToGrayscale(hex)
            return Blitbuffer.Color8(gray)
        elseif bg_color == "white" then
            return Blitbuffer.COLOR_WHITE
        elseif bg_color == "dark_gray" then
            return Blitbuffer.COLOR_DARK_GRAY
        elseif bg_color == "light_gray" then
            return Blitbuffer.COLOR_LIGHT_GRAY
        elseif bg_color == "gray" then
            return Blitbuffer.COLOR_GRAY
        elseif bg_color:match("^#%x%x%x%x?%x?%x?$") then
            local gray = hexToGrayscale(bg_color)
            return Blitbuffer.Color8(gray)
        else
            return Blitbuffer.COLOR_GRAY
        end
    end

    local function getTitleBgColor()
        if title_bg_color == "auto" then
            return getBgColor()
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

    local function getTitleFgColor()
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

    local function getAspectRatioAdjustedDimensions(width, height, border)
        local available_w = width - 2 * border
        local available_h = height - 2 * border
        local ratio = aspect_ratio

        local frame_w, frame_h
        if available_w / available_h > ratio then
            frame_h = available_h
            frame_w = available_h * ratio
        else
            frame_w = available_w
            frame_h = available_w / ratio
        end

        return { w = frame_w + 2 * border, h = frame_h + 2 * border }
    end

    local original_update = MosaicMenuItem.update

    function MosaicMenuItem:update(...)
        original_update(self, ...)

        if self.is_directory or not self.filepath then
            return
        end

        if self._default_cover_processed then
            return
        end

        local bookinfo = BookInfoManager:getBookInfo(self.filepath, false)
        
        if bookinfo and bookinfo.has_cover and not bookinfo.ignore_cover then
            return
        end

        self._default_cover_processed = true
        self._default_cover_frame_dimen = nil

        local frame_dimen = getAspectRatioAdjustedDimensions(self.width, self.height, frame_border_size)
        local inner_w = frame_dimen.w - 2 * frame_border_size
        local inner_h = frame_dimen.h - 2 * frame_border_size

        local title_text = nil
        if bookinfo and bookinfo.title then
            title_text = bookinfo.title
        else
            title_text = self.text or ""
            title_text = title_text:gsub("%.[^%.]+$", "")
        end
        title_text = BD.auto(title_text)

        local scaled_font_size = Screen:scaleBySize(title_font_size)

        local title_bg = getTitleBgColor()
        local title_fg = getTitleFgColor()

        -- Use grayscale colors and exclude from bg_color hook to avoid BGR buffer issues
        -- TextBoxWidget spans full width, no FrameContainer
        local title_widget = TextBoxWidget:new({
            text = title_text,
            face = Font:getFace(title_font_face, scaled_font_size),
            width = inner_w,
            alignment = "center",
            bold = title_font_bold,
            fgcolor = title_fg,
            bgcolor = title_bg,
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
                fgcolor = title_fg,
                bgcolor = title_bg,
                exclude_bg_color_hook = true,
            })
        end

        local title_overlay
        if title_bg then
            title_overlay = AlphaContainer:new({
                alpha = title_alpha,
                title_widget,
            })
        else
            title_overlay = title_widget
        end

        local title_overlay_size = title_overlay:getSize()

        local title_y_offset
        if title_position == "top" then
            title_y_offset = 0
        elseif title_position == "center" then
            title_y_offset = math.floor((inner_h - title_overlay_size.h) / 2)
        else
            title_y_offset = inner_h - title_overlay_size.h
        end

        local content = OverlapGroup:new({
            dimen = Geom:new({ w = inner_w, h = inner_h }),
        })

        title_overlay.overlap_offset = { 0, title_y_offset }
        table.insert(content, title_overlay)

        local framed_cover = FrameContainer:new({
            padding = 0,
            bordersize = frame_border_size,
            background = getBgColor(),
            content,
        })
        framed_cover.dimen = Geom:new({ w = frame_dimen.w, h = frame_dimen.h })

        local widget = CenterContainer:new({
            dimen = Geom:new({ w = self.width, h = self.height }),
            framed_cover,
        })

        self._cover_visual_widget = framed_cover
        self._default_cover_frame_dimen = frame_dimen

        self._underline_container[1] = widget
    end

    local orig_MosaicMenuItem_paintTo = MosaicMenuItem.paintTo

    function MosaicMenuItem:paintTo(bb, x, y)
        orig_MosaicMenuItem_paintTo(self, bb, x, y)

        if not self._default_cover_frame_dimen then
            return
        end

        local frame_dimen = self._default_cover_frame_dimen

        local fx = x + math.floor((self.width - frame_dimen.w) / 2)
        local fy = y + math.floor((self.height - frame_dimen.h) / 2)

        local inner_w = frame_dimen.w - 2 * frame_border_size
        local inner_h = frame_dimen.h - 2 * frame_border_size
        local icon_size = math.min(inner_w, inner_h) * icon_scale

        local book_icon = IconWidget:new({
            icon = "default.book.cover",
            width = icon_size,
            height = icon_size,
            alpha = true,
        })

        local icon_x = fx + frame_border_size + math.floor((inner_w - icon_size) / 2)
        local icon_y = fy + frame_border_size + math.floor((inner_h - icon_size) / 2)
        book_icon:paintTo(bb, icon_x, icon_y)
    end
end

userpatch.registerPatchPluginFunc("coverbrowser", patchDefaultCover)
