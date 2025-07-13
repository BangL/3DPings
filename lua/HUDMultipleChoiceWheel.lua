local _create_option_original = HUDMultipleChoiceWheel._create_option
local _create_icon_original = HUDMultipleChoiceWheel._create_icon

function HUDMultipleChoiceWheel:_create_option(index, angle, range, ...)
    local panel, icon, text, dx, dy = _create_option_original(self, index, angle, range, ...)
    if panel and self._tweak_data.no_text then
        dy = dy + 20
        panel:set_center_y(self._object:h() / 2 + dy)
    end
    return panel, icon, text, dx, dy
end

function HUDMultipleChoiceWheel:_create_icon(index, parent, ...)
    local icon = _create_icon_original(self, index, parent, ...)
    if icon and self._tweak_data.icons_max_height then
        local h = icon:h()
        local w = icon:w()
        icon:set_size(self._tweak_data.icons_max_height, h * self._tweak_data.icons_max_height / w)
    end
    return icon
end
