Hooks:PostHook(PlayerCarry, "_update_check_actions", "3DPings_PlayerCarry__update_check_actions",
    function(self, t, dt)
        self:_check_pings_wheel(t, dt)
    end
)
