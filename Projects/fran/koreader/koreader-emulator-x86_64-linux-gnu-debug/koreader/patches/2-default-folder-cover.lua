--[[ 
User patch for KOReader to show a default folder icon when a folder does not have a cover.
Maintains the same frame width and aspect ratio as books with covers.
Shows the folder name as an overlay.
]]
--

-- stylua: ignore start
--========================== [[Edit your preferences here]] ================================
local aspect_ratio = 2 / 3          -- Aspect ratio matching book covers (width/height)
local icon_scale = 0.40             -- Scale of the folder icon relative to cover size (0.1 to 0.6)
local bg_color = "#F5F0E6"          -- Library: warm cream paper
local title_font_face = "cfont"     -- Font face: "cfont" (default), "tfont", "infofont", "smallinfofont", etc.
local title_font_size = 16          -- Font size for the folder name
local title_font_bold = true        -- Bold text: true or false
local title_alpha = 1.0             -- Transparency of the title background (0-1)
local title_padding = 6             -- Padding around the folder name
local title_max_lines = 2           -- Maximum lines for the folder name
local title_position = "bottom"     -- Position: "top", "center", or "bottom"
local title_bg_color = "#F5F0E6"    -- Library: warm cream paper
local title_fg_color = "#2B2B2B"    -- Library: soft black ink
local cover_border = 0.5            -- Border thickness around the cover (in screen-scaled units)
local show_item_count = true        -- Show item count badge in top right corner
local item_count_font_size = 14     -- Font size for item count badge
--==========================================================================================
-- stylua: ignore end

local Blitbuffer = require("ffi/blitbuffer")
local Device = require("device")
local Screen = Device.screen
local userpatch = require("userpatch")

local function patchDefaultFolderCover(plugin)
    local AlphaContainer = require("ui/widget/container/alphacontainer")
    local BD = require("ui/bidi")
    local BottomContainer = require("ui/widget/container/bottomcontainer")
    local CenterContainer = require("ui/widget/container/centercontainer")
    local Font = require("ui/font")
    local FrameContainer = require("ui/widget/container/framecontainer")
    local Geom = require("ui/geometry")
    local IconWidget = require("ui/widget/iconwidget")
    local MosaicMenu = require("mosaicmenu")
    local OverlapGroup = require("ui/widget/overlapgroup")
    local RightContainer = require("ui/widget/container/rightcontainer")
    local TopContainer = require("ui/widget/container/topcontainer")
    local TextBoxWidget = require("ui/widget/textboxwidget")
    local TextWidget = require("ui/widget/textwidget")
    local logger = require("logger")
    local _ = require("gettext")

    local MosaicMenuItem = userpatch.getUpValue(MosaicMenu._updateItemsBuildUI, "MosaicMenuItem")

    if not MosaicMenuItem then
        logger.warn("Could not find MosaicMenuItem - default folder cover patch not applied")
        return
    end

    if MosaicMenuItem.patched_default_folder_cover then
        return
    end
    MosaicMenuItem.patched_default_folder_cover = true

    local function invertHexColor(hex)
        local r = tonumber(hex:sub(2, 3), 16)
        local g = tonumber(hex:sub(4, 5), 16)
        local b = tonumber(hex:sub(6, 7), 16)
        if not r or not g or not b then return hex end
        return string.format("#%02X%02X%02X", 255 - r, 255 - g, 255 - b)
    end

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
        elseif bg_color == "gray" then
            return Blitbuffer.COLOR_GRAY
        elseif bg_color == "light_gray" then
            return Blitbuffer.COLOR_LIGHT_GRAY
        elseif bg_color:match("^#%x%x%x%x?%x?%x?$") then
            local gray = hexToGrayscale(bg_color)
            return Blitbuffer.Color8(gray)
        else
            return Blitbuffer.COLOR_LIGHT_GRAY
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
            -- Convert custom hex to grayscale to avoid BGR issues
            local gray = hexToGrayscale(title_bg_color)
            return Blitbuffer.Color8(gray)
        else
            return Blitbuffer.COLOR_WHITE
        end
    end

    local function getTitleFgColor()
        if title_fg_color == "auto" then
            -- Use inverted grayscale of UI background for text
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

    local function getAspectRatioAdjustedDimensions(width, height)
        local ratio = aspect_ratio

        local frame_w, frame_h
        if width / height > ratio then
            frame_h = height
            frame_w = height * ratio
        else
            frame_w = width
            frame_h = width / ratio
        end

        return { w = frame_w, h = frame_h }
    end

    local function capitalize(sentence)
        local words = {}
        for word in sentence:gmatch("%S+") do
            table.insert(words, word:sub(1, 1):upper() .. word:sub(2):lower())
        end
        return table.concat(words, " ")
    end

    local function createDefaultFolderCover(self)
        local frame_dimen = getAspectRatioAdjustedDimensions(self.width, self.height)
        local inner_w = frame_dimen.w
        local inner_h = frame_dimen.h

        local folder_name = self.text or ""
        if folder_name:match("/$") then
            folder_name = folder_name:sub(1, -2)
        end
        
        local is_parent = self.entry and self.entry.is_go_up == true
        if is_parent then
            folder_name = ".."
        end
        folder_name = BD.directory(capitalize(folder_name))

        local scaled_font_size = Screen:scaleBySize(title_font_size)
        local scaled_padding = Screen:scaleBySize(title_padding)

        local title_bg = getTitleBgColor()
        local title_fg = getTitleFgColor()

        -- Use grayscale colors directly and exclude from bg_color hook
        -- TextBoxWidget spans full width, no FrameContainer padding
        local title_widget = TextBoxWidget:new({
            text = folder_name,
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
                text = folder_name,
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

        if show_item_count and self.mandatory then
            local count_str = self.mandatory:match("(%d+)")
            if count_str then
                local item_count = tonumber(count_str)
                if item_count and item_count > 0 then
                    local count_widget = TextWidget:new({
                        text = tostring(item_count),
                        face = Font:getFace("cfont", item_count_font_size),
                        bold = true,
                        padding = 0,
                        fgcolor = getTitleFgColor(),
                    })

                    local badge_margin = Screen:scaleBySize(5)
                    local nb_size = math.max(count_widget:getSize().w, count_widget:getSize().h)
                    local count_badge = TopContainer:new({
                        dimen = Geom:new({ w = inner_w, h = inner_h }),
                        RightContainer:new({
                            dimen = Geom:new({
                                w = inner_w - badge_margin,
                                h = nb_size + badge_margin * 2,
                            }),
                            FrameContainer:new({
                                padding = 2,
                                bordersize = 1,
                                radius = math.ceil(nb_size),
                                background = getTitleBgColor(),
                                CenterContainer:new({
                                    dimen = Geom:new({ w = nb_size, h = nb_size }),
                                    count_widget,
                                }),
                            }),
                        }),
                    })
                    table.insert(content, count_badge)
                end
            end
        end

        local framed_cover = FrameContainer:new({
            padding = 0,
            bordersize = 0,
            background = getBgColor(),
            content,
        })
        framed_cover.dimen = Geom:new({ w = frame_dimen.w, h = frame_dimen.h })

        local widget = CenterContainer:new({
            dimen = Geom:new({ w = self.width, h = self.height }),
            framed_cover,
        })

        self._cover_visual_widget = framed_cover
        self._has_icon_folder_cover = true
        self._icon_folder_frame_dimen = frame_dimen
        self._is_parent_folder = is_parent
        self._cover_top_shift = nil

        self._underline_container[1] = widget
    end

    local original_update = MosaicMenuItem.update

    function MosaicMenuItem:update(...)
        self._has_folder_image_cover = false
        self._has_icon_folder_cover = false
        self._icon_folder_frame_dimen = nil
        self._is_parent_folder = false
        
        original_update(self, ...)

        if not self.is_directory then
            return
        end

        if self._has_icon_folder_cover then
            return
        end

        if self._has_folder_image_cover then
            return
        end

        local is_parent = self.entry and self.entry.is_go_up == true
        self._is_parent_folder = is_parent
        self._icon_folder_frame_dimen = getAspectRatioAdjustedDimensions(self.width, self.height)

        createDefaultFolderCover(self)
    end

    local original_setFolderCover = MosaicMenuItem._setFolderCover
    if original_setFolderCover then
        function MosaicMenuItem:_setFolderCover(...)
            self._has_folder_image_cover = true
            return original_setFolderCover(self, ...)
        end
    end

    local corner_icons = {
        tl = "rounded.corner.tl",
        tr = "rounded.corner.tr",
        bl = "rounded.corner.bl",
        br = "rounded.corner.br",
    }

    local edge_icons = {
        top = "border.edge.top",
        bottom = "border.edge.bottom",
        left = "border.edge.left",
        right = "border.edge.right",
    }

    local orig_MosaicMenuItem_paintTo = MosaicMenuItem.paintTo

    function MosaicMenuItem:paintTo(bb, x, y)
        if self.is_directory and not self._has_folder_image_cover then
            local frame_dimen = getAspectRatioAdjustedDimensions(self.width, self.height)
            local fw, fh = frame_dimen.w, frame_dimen.h

            local fx = x + math.floor((self.width - fw) / 2)
            local fy = y + math.floor((self.height - fh) / 2)

            local is_parent = self.entry and self.entry.is_go_up == true
            local icon_size = math.min(fw, fh) * icon_scale
            local icon_name = is_parent and "default.folder.parent" or "default.folder.cover"
            local folder_icon = IconWidget:new({
                icon = icon_name,
                width = icon_size,
                height = icon_size,
                alpha = true,
            })

            local icon_x = fx + math.floor((fw - icon_size) / 2)
            local icon_y = fy + math.floor((fh - icon_size) / 2)
            folder_icon:paintTo(bb, icon_x, icon_y)
        end

        orig_MosaicMenuItem_paintTo(self, bb, x, y)

        if not self.is_directory then
            return
        end
        
        if self._has_folder_image_cover then
            return
        end

        local frame_dimen = getAspectRatioAdjustedDimensions(self.width, self.height)
        local fw, fh = frame_dimen.w, frame_dimen.h

        local fx = x + math.floor((self.width - fw) / 2)
        local fy = y + math.floor((self.height - fh) / 2)

        local tl = IconWidget:new({ icon = corner_icons.tl, alpha = true })
        local tr = IconWidget:new({ icon = corner_icons.tr, alpha = true })
        local bl = IconWidget:new({ icon = corner_icons.bl, alpha = true })
        local br = IconWidget:new({ icon = corner_icons.br, alpha = true })

        local tl_size = tl:getSize()
        local tr_size = tr:getSize()
        local bl_size = bl:getSize()
        local br_size = br:getSize()

        local border_width = Screen:scaleBySize(cover_border)
        local corner_radius = math.floor(math.max(bl_size.w, br_size.w) * 0.4)
        bb:paintRect(fx, fy, fw, border_width, Blitbuffer.COLOR_BLACK)
        bb:paintRect(fx, fy, border_width, fh, Blitbuffer.COLOR_BLACK)
        bb:paintRect(fx + fw - border_width, fy, border_width, fh, Blitbuffer.COLOR_BLACK)
        bb:paintRect(fx + corner_radius, fy + fh - border_width, fw - 2 * corner_radius, border_width, Blitbuffer.COLOR_BLACK)

        tl:paintTo(bb, fx, fy)
        tr:paintTo(bb, fx + fw - tr_size.w, fy)
        bl:paintTo(bb, fx, fy + fh - bl_size.h)
        br:paintTo(bb, fx + fw - br_size.w, fy + fh - br_size.h)
    end
end

userpatch.registerPatchPluginFunc("coverbrowser", patchDefaultFolderCover)
