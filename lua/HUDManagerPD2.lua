Hooks:PreHook(HUDManager, "on_simulation_ended", "3DPings_HUDManager_on_simulation_ended",
	function(self)
		self:_destroy_pings_wheel()
	end
)

Hooks:PreHook(PlayerManager, "set_player_state", "3DPings_PlayerManager_set_player_state",
	function(self, state, state_data)
		state = state or self._current_state
		if state == "bleed_out" then
			managers.hud:hide_pings_wheel(true)
		end
	end
)

function HUDManager:show_pings_wheel()
	if not self._hud_pings_wheel then
		self:_create_pings_wheel()
	end
	self._hud_pings_wheel:show()
end

function HUDManager:hide_pings_wheel(quiet)
	if self._hud_pings_wheel then
		self._hud_pings_wheel:hide(quiet)
	end
end

function HUDManager:is_pings_wheel_visible()
	if self._hud_pings_wheel ~= nil then
		return self._hud_pings_wheel:is_visible()
	end
	return false
end

function HUDManager:_create_pings_wheel_params()
	if not self._pings_wheel_params then
		self._pings_wheel_params = {
			cooldown = 0.5,
			icons_max_height = 42,
			no_text = true,
			show_clbks = { callback(managers.player, managers.player, "disable_view_movement") },
			hide_clbks = { callback(managers.player, managers.player, "enable_view_movement") },
			options = {},
		}
		for _, icon_id in ipairs(Pings.icons) do
			table.insert(self._pings_wheel_params.options, {
				icon = icon_id,
				id = "pings_icon_" .. icon_id,
				clbk = callback(self, self, "_pings_wheel_callback", icon_id),
				clbk_data = {},
			})
		end
	end

	return self._pings_wheel_params
end

function HUDManager:_pings_wheel_callback(icon_id)
	local mode = Pings:get_config_option("wheel_mode")
	if mode ~= 3 then -- select
		Pings:set_default_ping_icon(icon_id)
	end
	if mode ~= 2 then -- ping
		Pings:pop_ping(icon_id)
	end
end

function HUDManager:_create_pings_wheel()
	self._hud_pings_wheel = HUDMultipleChoiceWheel:new(self._saferect,
		managers.hud:script(PlayerBase.INGAME_HUD_SAFERECT), self:_create_pings_wheel_params())
	self._hud_pings_wheel:hide(true)
end

function HUDManager:_destroy_pings_wheel()
	if self._hud_pings_wheel then
		self._hud_pings_wheel:destroy()
		self._hud_pings_wheel = nil
	end
end
