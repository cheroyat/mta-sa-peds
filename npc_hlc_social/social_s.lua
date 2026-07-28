local SOCIAL = {
    enabled = true,
    checkInterval = 1000,
    chance = 3,
    distance = 3.2,
    durationMin = 5000,
    durationMax = 11000,
    cooldown = 18000,
    heightDifference = 2.0
}

local active = {}
local cooldownUntil = setmetatable({}, { __mode = "k" })
local greetings = {}
local greetingCooldownUntil = setmetatable({}, { __mode = "k" })

local function readSettings()
    local enabled = get("talking_enabled")
    local checkInterval = tonumber(get("talking_check_interval"))
    local chance = tonumber(get("talking_chance_percent"))
    local distance = tonumber(get("talking_distance"))
    local durationMin = tonumber(get("talking_duration_min"))
    local durationMax = tonumber(get("talking_duration_max"))
    local cooldown = tonumber(get("talking_cooldown"))

    SOCIAL.enabled = enabled ~= "false"
    SOCIAL.checkInterval = checkInterval or SOCIAL.checkInterval
    SOCIAL.chance = chance or SOCIAL.chance
    SOCIAL.distance = distance or SOCIAL.distance
    SOCIAL.durationMin = durationMin or SOCIAL.durationMin
    SOCIAL.durationMax = durationMax or SOCIAL.durationMax
    SOCIAL.cooldown = cooldown or SOCIAL.cooldown
end

local function validPed(ped)
    if not isElement(ped) or getElementType(ped) ~= "ped" then
        return false
    end

    if not exports.npc_hlc:isHLCEnabled(ped) then
        return false
    end

    if isPedInVehicle(ped) then
        return false
    end

    if getElementHealth(ped) < 1 then
        return false
    end

    if active[ped] then
        return false
    end

    local now = getTickCount()

    if (cooldownUntil[ped] or 0) > now then
        return false
    end

    return true
end

local function validGreetingPed(ped)
    return isElement(ped)
        and getElementType(ped) == "ped"
        and exports.npc_hlc:isHLCEnabled(ped)
        and not isPedInVehicle(ped)
        and getElementHealth(ped) >= 1
        and not active[ped]
        and not greetings[ped]
        and (greetingCooldownUntil[ped] or 0) <= getTickCount()
end

local function sameWorld(a, b)
    return getElementDimension(a) == getElementDimension(b)
        and getElementInterior(a) == getElementInterior(b)
end

local function closeEnough(a, b)
    if not sameWorld(a, b) then
        return false
    end

    local ax, ay, az = getElementPosition(a)
    local bx, by, bz = getElementPosition(b)

    if math.abs(az - bz) > SOCIAL.heightDifference then
        return false
    end

    return getDistanceBetweenPoints3D(ax, ay, az, bx, by, bz)
        <= SOCIAL.distance
end

local function faceEachOther(a, b)
    local ax, ay = getElementPosition(a)
    local bx, by = getElementPosition(b)

    setPedRotation(a, -math.deg(math.atan2(bx - ax, by - ay)))
    setPedRotation(b, -math.deg(math.atan2(ax - bx, ay - by)))
end

local function finishConversation(ped)
    local data = active[ped]

    if not data then
        return
    end

    local partner = data.partner
    active[ped] = nil
    cooldownUntil[ped] = getTickCount() + SOCIAL.cooldown

    if isElement(ped) then
        setElementFrozen(ped, false)
        setElementData(ped, "npc_social:state", false, true)
        setElementData(ped, "npc_social:partner", false, true)
    end

    if isElement(partner) and active[partner] then
        active[partner] = nil
        cooldownUntil[partner] = getTickCount() + SOCIAL.cooldown
        setElementFrozen(partner, false)
        setElementData(partner, "npc_social:state", false, true)
        setElementData(partner, "npc_social:partner", false, true)
    end
end

local function finishGreeting(ped)
    local data = greetings[ped]
    if not data then return end

    local partner = data.partner
    greetings[ped] = nil
    greetingCooldownUntil[ped] = getTickCount() + tonumber(get("greeting_cooldown") or 12000)

    if isElement(ped) then
        setElementFrozen(ped, false)
        setElementData(ped, "npc_social:state", false, true)
        setElementData(ped, "npc_social:partner", false, true)
    end

    if isElement(partner) then
        greetings[partner] = nil
        greetingCooldownUntil[partner] = getTickCount() + tonumber(get("greeting_cooldown") or 12000)
        setElementFrozen(partner, false)
        setElementData(partner, "npc_social:state", false, true)
        setElementData(partner, "npc_social:partner", false, true)
    end
end

local function startGreeting(a, b)
    if not validGreetingPed(a) or not validGreetingPed(b) or not closeEnough(a, b) then
        return false
    end

    greetings[a] = { partner = b, endsAt = getTickCount() + tonumber(get("greeting_duration") or 2200) }
    greetings[b] = { partner = a, endsAt = greetings[a].endsAt }
    faceEachOther(a, b)
    setElementFrozen(a, true)
    setElementFrozen(b, true)
    setElementData(a, "npc_social:state", "greet", true)
    setElementData(a, "npc_social:partner", b, true)
    setElementData(b, "npc_social:state", "greet", true)
    setElementData(b, "npc_social:partner", a, true)
    return true
end

local function updateGreetings()
    local now = getTickCount()
    for ped, data in pairs(greetings) do
        if not isElement(ped)
            or not isElement(data.partner)
            or getElementHealth(ped) < 1
            or now >= data.endsAt
        then
            finishGreeting(ped)
        end
    end
end

local function finishIfInvalid(ped)
    local data = active[ped]

    if not data then
        return false
    end

    local partner = data.partner

    if not isElement(ped)
        or not isElement(partner)
        or getElementHealth(ped) < 1
        or getElementHealth(partner) < 1
        or not closeEnough(ped, partner)
    then
        finishConversation(ped)
        return true
    end

    if getTickCount() >= data.endsAt then
        finishConversation(ped)
        return true
    end

    return false
end

local function startConversation(a, b)
    if not validPed(a) or not validPed(b) then
        return false
    end

    if not closeEnough(a, b) then
        return false
    end

    local duration = math.random(
        SOCIAL.durationMin,
        SOCIAL.durationMax
    )

    local endsAt = getTickCount() + duration
    local style = math.random(1, 3)

    active[a] = { partner = b, endsAt = endsAt }
    active[b] = { partner = a, endsAt = endsAt }

    faceEachOther(a, b)
    setElementFrozen(a, true)
    setElementFrozen(b, true)

    setElementData(a, "npc_social:state", "talk", true)
    setElementData(a, "npc_social:partner", b, true)
    setElementData(a, "npc_social:role", "speaker", true)
    setElementData(a, "npc_social:style", style, true)

    setElementData(b, "npc_social:state", "talk", true)
    setElementData(b, "npc_social:partner", a, true)
    setElementData(b, "npc_social:role", "listener", true)
    setElementData(b, "npc_social:style", style, true)

    return true
end

local function findPartner(ped, candidates)
    local px, py, pz = getElementPosition(ped)
    local best
    local bestDistance = math.huge

    for _, other in ipairs(candidates) do
        if other ~= ped and validPed(other) then
            if closeEnough(ped, other) then
                local ox, oy, oz = getElementPosition(other)
                local distance = getDistanceBetweenPoints3D(
                    px, py, pz, ox, oy, oz
                )

                if distance < bestDistance then
                    best = other
                    bestDistance = distance
                end
            end
        end
    end

    return best
end

local function scanSocialPeds()
    if not SOCIAL.enabled then
        return
    end

    local allPeds = getElementsByType("ped", root)

    for ped in pairs(active) do
        finishIfInvalid(ped)
    end

    for _, ped in ipairs(allPeds) do
        if validPed(ped) and math.random(1, 100) <= SOCIAL.chance then
            local partner = findPartner(ped, allPeds)

            if partner then
                startConversation(ped, partner)
            end
        end
    end

    local greetingChance = tonumber(get("greeting_chance_percent")) or 2
    local greetingDistance = tonumber(get("greeting_distance")) or 3.0

    for _, ped in ipairs(allPeds) do
        if validGreetingPed(ped) and math.random(1, 100) <= greetingChance then
            local px, py, pz = getElementPosition(ped)
            for _, other in ipairs(allPeds) do
                if other ~= ped and validGreetingPed(other) then
                    local ox, oy, oz = getElementPosition(other)
                    if getDistanceBetweenPoints3D(px, py, pz, ox, oy, oz) <= greetingDistance then
                        if startGreeting(ped, other) then break end
                    end
                end
            end
        end
    end

    updateGreetings()
end

local function onPedDestroyed()
    if active[source] then
        finishConversation(source)
    end
    if greetings[source] then
        finishGreeting(source)
    end

    cooldownUntil[source] = nil
end

addEventHandler("onElementDestroy", root, onPedDestroyed)
addEventHandler("onPedWasted", root, function()
    if active[source] then
        finishConversation(source)
    end
end)

addEventHandler("onResourceStart", resourceRoot, function()
    readSettings()
    setTimer(scanSocialPeds, SOCIAL.checkInterval, 0)
end)
