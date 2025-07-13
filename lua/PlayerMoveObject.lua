Hooks:PostHook(PlayerMoveObject, "_update_check_actions", "3DPings_PlayerMoveObject__update_check_actions",
    function(self, t, dt)
        self:_check_pings_wheel(t, dt)
    end
)
