local fights = {}
local cooldown = setmetatable({}, { __mode = "k" })

local function freePed(ped)
    return isElement(ped)
        and getElementType(ped) == "ped"
        and exports.npc_hlc:isHLCEnabled(ped)
        and not isPedInVehicle(ped)
        and getElementHealth(ped) > 0
        and not fights[ped]
        and (cooldown[ped] or 0) <= getTickCount()
        and not getElementData(ped, "npc_social:state")
end

local function near(a, b)
    if getElementDimension(a) ~= getElementDimension(b)
        or getElementInterior(a) ~= getElementInterior(b) then
        return false
    end

    local ax, ay, az = getElementPosition(a)
    local bx, by, bz = getElementPosition(b)
    return math.abs(az - bz) < 2.0
        and getDistanceBetweenPoints3D(ax, ay, az, bx, by, bz)
            <= (tonumber(get("fight_distance")) or 2.8)
end

local function stopFight(ped)
    local data = fights[ped]
    if not data then return end

    local other = data.other
    fights[ped] = nil
    cooldown[ped] = getTickCount() + (tonumber(get("fight_cooldown")) or 30000)

    if isElement(ped) then
        setElementData(ped, "npc_social:state", false, true)
        setElementData(ped, "npc_social:partner", false, true)
    end

    if isElement(other) and fights[other] then
        fights[other] = nil
        cooldown[other] = getTickCount() + (tonumber(get("fight_cooldown")) or 30000)
        setElementData(other, "npc_social:state", false, true)
        setElementData(other, "npc_social:partner", false, true)
    end
end

local function startFight(a, b)
    if not freePed(a) or not freePed(b) or not near(a, b) then
        return false
    end

    local now = getTickCount()
    fights[a] = { other = b, nextHit = now + 500 }
    fights[b] = { other = a, nextHit = now + 900 }

    setElementData(a, "npc_social:state", "fight", true)
    setElementData(a, "npc_social:partner", b, true)
    setElementData(b, "npc_social:state", "fight", true)
    setElementData(b, "npc_social:partner", a, true)
    return true
end

local function updateFights()
    local now = getTickCount()
    local damage = tonumber(get("fight_damage")) or 7
    local interval = tonumber(get("fight_hit_interval")) or 850

    for ped, data in pairs(fights) do
        local other = data.other

        if not isElement(ped)
            or not isElement(other)
            or getElementHealth(ped) <= 0
            or getElementHealth(other) <= 0
            or not near(ped, other)
        then
            stopFight(ped)
        elseif now >= data.nextHit then
            local health = getElementHealth(other)
            if health <= damage then
                killPed(other, ped, 0, 3)
            else
                setElementHealth(other, health - damage)
            end
            data.nextHit = now + interval + math.random(-120, 120)
        end
    end
end

local function scanFights()
    local peds = getElementsByType("ped", root)
    local chance = tonumber(get("fight_chance_percent")) or 0.4

    for _, ped in ipairs(peds) do
        if freePed(ped) and math.random() * 100 <= chance then
            local x, y, z = getElementPosition(ped)
            local nearby = getElementsWithinRange(
                x, y, z, tonumber(get("fight_distance")) or 2.8,
                "ped", getElementInterior(ped), getElementDimension(ped)
            )

            for _, other in ipairs(nearby) do
                if other ~= ped and freePed(other) and startFight(ped, other) then
                    break
                end
            end
        end
    end
end

addEventHandler("onElementDestroy", root, function()
    if fights[source] then stopFight(source) end
    cooldown[source] = nil
end)

addEventHandler("onPedWasted", root, function()
    if fights[source] then stopFight(source) end
end)

addEventHandler("onResourceStart", resourceRoot, function()
    setTimer(scanFights, 1000, 0)
    setTimer(updateFights, 100, 0)
end)
