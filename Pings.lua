Pings = Pings or {}

--#region config

Pings._config_defaults_path = ModPath .. "default_config.json"
Pings._config_path = SavePath .. "3DPings.json"
Pings._config = {}
Pings._config_defaults = {}

function Pings:save_config()
    local file = io.open(self._config_path, "w+")
    if file then
        file:write(json.encode(self._config))
        file:close()
    end
end

function Pings:load_config()
    self._config = clone(self._config_defaults)
    local file = io.open(self._config_path, "r")
    if file then
        local config = json.decode(file:read("*all"))
        file:close()
        if config and (type(config) == "table") then
            for k, v in pairs(config) do
                self._config[k] = v
            end
        end
    end
end

function Pings:get_config_option(id)
    return self._config[id]
end

function Pings:set_config_option(id, value)
    if self._config[id] ~= value then
        self._config[id] = value
        return true
    end

    return false
end

function Pings:load_config_defaults()
    local default_file = io.open(self._config_defaults_path)
    if default_file then
        self._config_defaults = json.decode(default_file:read("*all"))
        default_file:close()
    end
end

--#endregion config

--#region pings

Pings._active_pings = {}

function Pings:_get_icon_data(icon_id)
    local icon_tweak = tweak_data.gui.icons[icon_id]
    return icon_tweak.texture, icon_tweak.texture_rect
end

function Pings:set_default_ping_icon(icon_id)
    self._default_icon_id = icon_id
end

function Pings:pop_ping(icon_id, peer, position)
    icon_id = icon_id or self._default_icon_id or self:get_config_option("default_icon")
    peer = peer or managers.network:session():local_peer()
    local unit = peer._unit
    if not unit then
        return
    end
    if not position then
        local camera = unit:camera()
        local cam_pos = camera:position()
        position = World:raycast("ray", cam_pos, cam_pos + camera:rotation():y() * 50000).position
    end
    local is_own_ping = (unit == managers.player:player_unit())
    local waypoint_id = self:_get_waypoint_id_for_peer(peer:id())

    local scale = self:get_config_option("ping_scale")
    local alpha = self:get_config_option("ping_alpha")
    local lifetime = self:get_config_option("ping_lifetime")
    local fade_out_duration = self:get_config_option("ping_fade_out_duration")
    local show_name = self:get_config_option("ping_show_name")
    local show_distance = self:get_config_option("ping_show_distance")
    local colorize_pings = self:get_config_option("colorize_pings")
    local texture, texture_rect = self:_get_icon_data(icon_id)

    local color = Color.white
    if colorize_pings then
        local color_id = managers.criminals:character_color_id_by_unit(unit)
        if WolfgangHUD then
            color_id = WolfgangHUD:character_color_id(unit, self._id)
        end
        color = tweak_data.chat_colors[color_id] or tweak_data.chat_colors[#tweak_data.chat_colors]
    end

    local fade_duration = {
        start = math.max(0, lifetime - fade_out_duration) / lifetime,
        stop = 1,
        alpha = true,
    }
    managers.waypoints:add_waypoint(waypoint_id, "CustomWaypoint", {
        position = position,
        scale = scale,
        alpha = alpha,
        color = color,
        visible_through_walls = true,
        show_offscreen = true,
        hide_on_uninteractable = false,
        radius_offscreen = 400,
        visible_angle = { max = 360 },
        visible_distance = { max = 20000 },
        rescale_distance = {
            start_distance = 10,
            end_distance = 10000,
            final_scale = 0.5
        },
        fade_duration = fade_duration,
        duration = {
            type = "duration",
            show = false,
            initial_value = lifetime,
            fade_duration = fade_duration,
        },
        icon = {
            type = "icon",
            show = true,
            scale = scale * 1.5,
            texture = texture,
            texture_rect = texture_rect,
            blend_mode = "normal",
        },
        name = {
            type = "label",
            show = show_name,
            text = peer._name,
            font = tweak_data.gui.fonts.din_compressed_outlined_18,
        },
        distance = {
            type = "distance",
            show = show_distance,
            font = tweak_data.gui.fonts.din_compressed_outlined_18,
        },
        component_order = { { "icon" }, { "name" }, { "distance" } },
    }, true)

    if is_own_ping then
        Pings.Sync:send_to_known_peers(Pings.Sync.events.pop_ping, {
            x = position.x,
            y = position.y,
            z = position.z,
            icon_id = icon_id,
        })
    end

    self._last_ping_lifetime = lifetime
    self._active_pings[waypoint_id] = TimerManager:game():time()

    return waypoint_id
end

function Pings:has_active_pings()
    return (self._last_ping_lifetime and next(self._active_pings)) and true or false
end

function Pings:clear_pings()
    if self:has_active_pings() then
        self._clear_pings = true
    end
end

function Pings:_on_update()
    local clearing_pings
    if self._clear_pings then
        clearing_pings = self._clear_pings
        self._clear_pings = nil
    end
    if not self:has_active_pings() then
        return
    end
    local removed_pings = {}
    for waypoint_id, ping_time in pairs(self._active_pings) do
        if clearing_pings or ((TimerManager:game():time() - ping_time) > self._last_ping_lifetime) then
            managers.waypoints:remove_waypoint(waypoint_id)
            table.insert(removed_pings, waypoint_id)
        end
    end
    for _, waypoint_id in pairs(removed_pings) do
        self._active_pings[waypoint_id] = nil
    end
end

function Pings:_get_waypoint_id_for_peer(peer_id)
    self._last_peer_ping_ids = self._last_peer_ping_ids or {}
    local ping_id = (self._last_peer_ping_ids[peer_id] or 0) + 1
    if (not ping_id) or (ping_id > self:get_config_option("max_pings_per_player")) then
        ping_id = 1
    end
    self._last_peer_ping_ids[peer_id] = ping_id
    return "ping_" .. tostring(ping_id) .. "_of_peer_" .. tostring(peer_id)
end

--#endregion pings

function Pings:announce_peer_uses_mod(peer)
    if self:get_config_option("announce_player_uses_pings_mod") then
        managers.chat:feed_system_message(ChatManager.GAME, managers.localization:text("pings_player_uses_pings_mod", {
            PLAYER = peer:name(),
        }))
    end
end

function Pings:init_icons()
    local tweak_file = "PingsIcons.lua"
    local tweak_path = string.format("%s%s", SavePath, tweak_file)
    if not io.file_is_readable(tweak_path) then
        tweak_path = string.format("%s%s", ModPath, tweak_file)
    end
    dofile(tweak_path)
    table.sort(self.icons)
end

Pings:load_config_defaults()
Pings:load_config()
Pings:init_icons()
