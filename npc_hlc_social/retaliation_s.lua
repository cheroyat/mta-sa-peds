local retaliation = {}
local targetOf = {}

addEvent("npc_social:onPlayerMeleeHit", true)

local function isMeleeWeapon(weapon)
    weapon = tonumber(weapon)
    return weapon == 0
        or (weapon >= 1 and weapon <= 8)
        or (weapon >= 10 and weapon <= 14)
end

local function clearRetaliation(ped)
    local data = retaliation[ped]
    if not data then return end
    if isElement(data.target) and targetOf[data.target] == ped then
        targetOf[data.target] = nil
    end
    retaliation[ped] = nil
    if isElement(ped) then
        setElementData(ped, "npc_social:state", false, true)
        setElementData(ped, "npc_social:partner", false, true)
    end
end

local function startRetaliation(ped, player, weapon)
    if not isElement(ped) or getElementType(ped) ~= "ped"
        or not isElement(player) or getElementType(player) ~= "player"
        or not isMeleeWeapon(weapon) or getElementHealth(ped) <= 0
        or not exports.npc_hlc:isHLCEnabled(ped) then
        return
    end

    if targetOf[player] and targetOf[player] ~= ped then
        clearRetaliation(targetOf[player])
    end

    retaliation[ped] = {
        target = player,
        untilTime = getTickCount() + (tonumber(get("retaliation_duration")) or 20000),
        nextHit = getTickCount() + 600
    }
    targetOf[player] = ped
    setElementData(ped, "npc_social:state", "retaliate", true)
    setElementData(ped, "npc_social:partner", player, true)
end

addEventHandler("onPedDamage", root, function(attacker, weapon)
    if isElement(attacker) and getElementType(attacker) == "player" then
        startRetaliation(source, attacker, weapon)
    end
end)

addEventHandler("npc_social:onPlayerMeleeHit", root, function(ped, weapon)
    outputDebugString(
        "[npc_hlc_social] retaliation event from "
        .. tostring(client)
        .. " ped="
        .. tostring(ped)
        .. " weapon="
        .. tostring(weapon),
        3
    )

    if client then
        startRetaliation(ped, client, weapon)
    end
end)

local function updateRetaliation()
    local now = getTickCount()
    local range = tonumber(get("retaliation_hit_distance")) or 2.0
    local interval = tonumber(get("retaliation_hit_interval")) or 900
    local damage = tonumber(get("retaliation_damage")) or 6

    for ped, data in pairs(retaliation) do
        local player = data.target
        if not isElement(ped) or not isElement(player)
            or getElementHealth(ped) <= 0
            or getElementHealth(player) <= 0
            or now >= data.untilTime then
            clearRetaliation(ped)
        else
            local x, y, z = getElementPosition(ped)
            local px, py, pz = getElementPosition(player)
            if getDistanceBetweenPoints3D(x, y, z, px, py, pz) <= range
                and now >= data.nextHit then
                setElementHealth(player, math.max(0, getElementHealth(player) - damage))
                data.nextHit = now + interval
            end
        end
    end
end

addEventHandler("onElementDestroy", root, function()
    if retaliation[source] then clearRetaliation(source) end
    if targetOf[source] then clearRetaliation(targetOf[source]) end
end)
addEventHandler("onPlayerQuit", root, function()
    if targetOf[source] then clearRetaliation(targetOf[source]) end
end)
addEventHandler("onPedWasted", root, function()
    if retaliation[source] then clearRetaliation(source) end
end)
addEventHandler("onResourceStart", resourceRoot, function()
    setTimer(updateRetaliation, 100, 0)
end)
