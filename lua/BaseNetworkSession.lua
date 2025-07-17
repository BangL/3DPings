-- networking

if not Pings.Sync then
    Pings.Sync = {
        msg_id = "3DPings",
        peers = { false, false, false, false },
        events = {
            handshake = "handshake",
            rejected = "rejected",
            pop_ping = "pop_ping",
        },
        valid = {
            server = 0,
            client = 1,
            both = 2,
        },
        protocol_version = 1
    }

    function Pings.Sync.table_to_string(tbl)
        return LuaNetworking:TableToString(tbl) or ""
    end

    function Pings.Sync.string_to_table(str)
        local tbl = LuaNetworking:StringToTable(str) or {}

        for k, v in pairs(tbl) do
            tbl[k] = Pings.Sync.to_original_type(v)
        end

        return tbl
    end

    function Pings.Sync.to_original_type(s)
        local v = s
        if type(s) == "string" then
            if s == "nil" then
                v = nil
            elseif (s == "true") or (s == "false") then
                v = (s == "true")
            else
                v = tonumber(s) or s
            end
        end
        return v
    end

    function Pings.Sync:_validate(valid_on, valid_from, peer_id)
        if (valid_on == self.valid.server) and Network:is_client() then
            self:send_to_peer(peer_id, self.events.rejected, "clients cannot handle this.")
            return false
        end
        if (valid_on == self.valid.client) and Network:is_server() then
            self:send_to_peer(peer_id, self.events.rejected, "the host cannot handle this.")
            return false
        end
        if (valid_from == self.valid.server) and (peer_id ~= 1) then
            self:send_to_peer(peer_id, self.events.rejected, "only the host is allowed to send this.")
            return false
        end
        if (valid_from == self.valid.client) and (peer_id == 1) then
            self:send_to_peer(peer_id, self.events.rejected, "only clients are allowed to send this.")
            return false
        end
        return managers.network:session():peer(peer_id)
    end

    function Pings.Sync:send_to_peer(peer_id, event, data)
        if peer_id and (peer_id ~= LuaNetworking:LocalPeerID()) and event then
            local tags = {
                id = self.msg_id,
                event = event
            }

            if type(data) == "table" then
                data = self.table_to_string(data)
            end
            LuaNetworking:SendToPeer(peer_id, self.table_to_string(tags), data or "")
        end
    end

    function Pings.Sync:send_to_host(event, data)
        self:send_to_peer(managers.network:session():server_peer():id(), event, data)
    end

    function Pings.Sync:send_to_known_peers(event, data)
        for peer_id, known in ipairs(self.peers) do
            if known and (peer_id ~= managers.network:session():local_peer():id()) then
                self:send_to_peer(peer_id, event, data)
            end
        end
    end

    function Pings.Sync:send_to_unknown_peers(event, data)
        for peer_id, known in ipairs(self.peers) do
            if (not known) and (peer_id ~= managers.network:session():local_peer():id()) then
                self:send_to_peer(peer_id, event, data)
            end
        end
    end

    function Pings.Sync:peer_has_mod(peer_id)
        return (peer_id == managers.network:session():local_peer():id()) or
            (Network:is_server() and (peer_id == 1)) or
            self.peers[peer_id]
    end

    function Pings.Sync:host_has_mod()
        return self:peer_has_mod(1)
    end

    function Pings.Sync:reset_peer(peer_id)
        if self.peers[peer_id] then
            self.peers[peer_id] = false
        end
    end

    function Pings.Sync:receive(sender, tags, data)
        sender = tonumber(sender)
        if sender then
            tags = self.string_to_table(tags)
            if tags.id and (tags.id == self.msg_id) and not string.is_nil_or_empty(tags.event) then
                data = self.string_to_table(data)
                if self.events[tags.event] and self[tags.event] then
                    self[tags.event](self, sender, data)
                elseif tags.event ~= self.events.rejected then
                    self:send_to_peer(sender, self.events.rejected, "event unknown.")
                end
            end
        end
    end

    -- bidirectional event handlers

    function Pings.Sync:handshake(peer_id, data)
        local peer = self:_validate(self.valid.both, self.valid.both, peer_id)
        if not peer then
            return
        end

        if tostring(data.version) ~= tostring(self.protocol_version) then
            log("[3DPings.Sync handshake] received handshake, but wrong protocol version. skipping. local version: " ..
                tostring(self.protocol_version) .. ", remote version: " .. tostring(data.version))
            return
        end

        log("[3DPings.Sync handshake] Peer " .. tostring(peer_id) .. " is using a compatible 3DPings version.")

        if not self.peers[peer_id] then
            self:send_to_peer(peer_id, self.events.handshake, {
                version = self.protocol_version
            })
            Pings:announce_peer_uses_mod(peer)
            self.peers[peer_id] = true
        end
    end

    function Pings.Sync:pop_ping(peer_id, data)
        local peer = self:_validate(self.valid.both, self.valid.both, peer_id)
        if not peer then
            return
        end
        if data.x and data.y and data.z and data.icon_id then
            Pings:pop_ping(data.icon_id, peer, Vector3(data.x, data.y, data.z))
        end
    end
end

Hooks:Add("BaseNetworkSessionOnLoadComplete", "3DPings.Sync_BaseNetworkSessionOnLoadComplete",
    function(local_peer, id)
        if Pings.Sync and LuaNetworking:IsMultiplayer() and Network:is_client() then
            -- client handshake request to host
            Pings.Sync:send_to_unknown_peers(Pings.Sync.events.handshake,
                { version = Pings.Sync.protocol_version })
        end
    end
)

Hooks:Add("BaseNetworkSessionOnPeerRemoved", "3DPings.Sync_BaseNetworkSessionOnPeerRemoved",
    function(peer, peer_id, reason)
        if Pings.Sync then
            -- reset handshake
            Pings.Sync:reset_peer(peer_id)
        end
    end
)

Hooks:Add("NetworkReceivedData", "3DPings.Sync_NetworkReceivedData",
    function(sender, tags, data)
        if Pings.Sync then
            Pings.Sync:receive(sender, tags, data)
        end
    end
)
