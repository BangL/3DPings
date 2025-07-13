Hooks:PostHook(PlayerStandard, "_update_check_actions", "3DPings_PlayerStandard__update_check_actions",
    function(self, t, dt)
        self:_check_pings_wheel(t, dt)
    end
)

local _is_comm_wheel_active_original = PlayerStandard._is_comm_wheel_active
function PlayerStandard:_is_comm_wheel_active()
    return _is_comm_wheel_active_original(self) or managers.hud:is_pings_wheel_visible()
end

function PlayerStandard:_check_pings_wheel()
    local action_forbidden = self:chk_action_forbidden("comm_wheel") or self._unit:base():stats_screen_visible() or
        self:_interacting() or self._ext_movement:has_carry_restriction() or self:is_deploying() or
        self:_is_throwing_projectile() or self:_is_meleeing() or self:_on_zipline() or self:_mantling()

    if action_forbidden then
        return
    end

    local bind = BLT.Keybinds:get_keybind("pings_wheel_hotkey")
    local key_pressed = false
    local key_released = false
    if bind:IsActive() and bind:HasKey() then
        local key = bind:Key()
        if string.find(key, "mouse ") == 1 then
            if not string.find(key, "wheel") then
                key = key:sub(7)
            end
            key_pressed = Input:mouse():pressed(Idstring(key))
            key_released = Input:mouse():released(Idstring(key))
        else
            key_pressed = Input:keyboard():pressed(Idstring(key))
            key_released = Input:keyboard():released(Idstring(key))
        end
    end

    local wheel_active = self:_is_comm_wheel_active()

    if (not wheel_active) and key_pressed then
        managers.hud:show_pings_wheel()
    end

    if wheel_active and (self._ext_movement.setting_hold_to_wheel and key_released or key_pressed) then
        managers.hud:hide_pings_wheel()
    end
end
