-- options menu

PingsMenu = PingsMenu or class(BLTMenu)

function PingsMenu:Init(root)
	self._something_changed = false

	self:_MakeHeader()

	self:_MakeSeparator()
	self:_MakeOptionMultiChoiceIcons("default_icon", Pings.icons)
	self:_MakeOptionMultiChoice("wheel_mode", {
		"wheel_mode_select_and_ping",
		"wheel_mode_just_select",
		"wheel_mode_just_ping",
	})

	self:_MakeSeparator()
	self:_MakeOptionToggle("announce_player_uses_pings_mod")
	self:_MakeOptionSlider("max_pings_per_player", 0, 100)

	self:_MakeSeparator()
	self:_MakeOptionToggle("ping_show_name")
	self:_MakeOptionToggle("ping_show_distance")
	self:_MakeOptionToggle("colorize_pings")
	self:_MakeOptionSlider("ping_scale", 0.1, 3, 2)
	self:_MakeOptionSlider("ping_alpha", 0.1, 1, 2)
	self:_MakeOptionSlider("ping_lifetime", 1, 120)
	self:_MakeOptionSlider("ping_fade_out_duration", 1, 120)

	self:_MakeResetButton()
end

function PingsMenu:_MakeHeader()
	self:Title({
		text = "pings_title",
	})
	self:Label({
		text = nil,
		localize = false,
		h = 8,
	})
end

function PingsMenu:_MakeResetButton()
	self:LongRoundedButton2({
		name = "pings_reset",
		text = "pings_reset",
		localize = true,
		callback = callback(self, self, "Reset"),
		ignore_align = true,
		y = 832,
		x = 1472,
	})
end

function PingsMenu:_MakeSeparator(text, localize)
	self:SubTitle({ text = text, localize = localize, y_offset = text and 0 or 8 })
end

function PingsMenu:_MakeOptionToggle(option)
	local id = "pings_" .. option
	self:Toggle({
		name = id,
		text = id,
		desc = id .. "_desc",
		value = Pings:get_config_option(option),
		callback = callback(self, self, "OnOptionChanged", option),
	})
end

function PingsMenu:_MakeOptionSlider(option, min, max, decimals)
	local id = "pings_" .. option
	self:Slider({
		name = id,
		text = id,
		desc = id .. "_desc",
		value = Pings:get_config_option(option),
		callback = callback(self, self, "OnOptionChanged", option),
		min = min or 0,
		max = max or 100,
		value_format = "%." .. (decimals or 0) .. "f",
	})
end

function PingsMenu:_MakeOptionMultiChoice(option, items)
	local id = "pings_" .. option
	local params = {
		name = id,
		text = id,
		desc = id .. "_desc",
		value = Pings:get_config_option(option),
		callback = callback(self, self, "OnOptionChanged", option),
		items = {},
	}
	for i, opt_id in ipairs(items) do
		table.insert(params.items, {
			text_id = "pings_" .. opt_id,
			value = i,
		})
	end
	self:MultiChoice(params)
end

function PingsMenu:_MakeOptionMultiChoiceIcons(option, items)
	local id = "pings_" .. option
	local params = {
		name = id,
		text = id,
		desc = id .. "_desc",
		value = Pings:get_config_option(option),
		callback = callback(self, self, "OnOptionChanged", option),
		items = {},
	}
	for _, opt_id in ipairs(items) do
		table.insert(params.items, {
			icon_id = opt_id,
			value = opt_id,
		})
	end
	self:MultiChoiceIcons(params)
end

function PingsMenu:OnOptionChanged(option, value)
	if Pings:set_config_option(option, (type(value) == "table") and value.value or value) then
		if option == "default_icon" then
			self._selected_icon_id = value.value
		end
		self._something_changed = true
	end
end

function PingsMenu:Reset(value, item)
	QuickMenu:new(
		managers.localization:text("pings_reset"),
		managers.localization:text("pings_reset_confirm"),
		{
			[1] = {
				text = managers.localization:text("dialog_no"),
				is_cancel_button = true,
			},
			[2] = {
				text = managers.localization:text("dialog_yes"),
				callback = function()
					-- reset config
					Pings:load_config_defaults()
					Pings:save_config()
					-- reset menu
					self._something_changed = false
					self:ReloadMenu()
				end,
			},
		},
		true
	)
end

function PingsMenu:Close()
	if self._something_changed then
		Pings:save_config()
	end
end

Hooks:Add("MenuComponentManagerInitialize", "3DPings_MenuComponentManagerInitialize",
	function(self)
		RaidMenuHelper:CreateMenu({
			name = "pings_options",
			name_id = "pings_title",
			inject_menu = "blt_options",
			class = PingsMenu
		})
	end
)
