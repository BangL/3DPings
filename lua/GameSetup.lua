
Hooks:PostHook(GameSetup, "update", "3DPings_GameSetup_update",
    function(self, t, dt)
        Pings:_on_update()
    end
)
