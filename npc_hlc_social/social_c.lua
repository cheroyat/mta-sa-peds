local function isMeleeWeapon(weapon)
    weapon = tonumber(weapon)
    return weapon == 0
        or (weapon >= 1 and weapon <= 8)
        or (weapon >= 10 and weapon <= 14)
end

local TALK_ANIMATIONS = {
    speaker = {
        { "gangs", "prtial_gngtlka" },
        { "gangs", "prtial_gngtlkc" },
        { "gangs", "prtial_gngtlke" }
    },

    listener = {
        { "gangs", "prtial_gngtlkb" },
        { "gangs", "prtial_gngtlkd" },
        { "gangs", "prtial_gngtlkf" }
    }
}

local GREETING_ANIMATIONS = {
    { "gangs", "hndshkaa" },
    { "gangs", "hndshkba" },
    { "gangs", "hndshkca" },
    { "on_lookers", "wave_loop" }
}

local lastAnimation = setmetatable({}, { __mode = "k" })

local function stopPedMovement(ped)
    if type(stopAllNPCActions) == "function" then
        stopAllNPCActions(ped)
        return
    end

    setPedControlState(ped, "forwards", false)
    setPedControlState(ped, "sprint", false)
    setPedControlState(ped, "walk", false)
    setPedControlState(ped, "fire", false)
    setPedControlState(ped, "aim_weapon", false)
    setElementVelocity(ped, 0, 0, 0)
end

local function getAnimation(ped)
    local role = getElementData(ped, "npc_social:role")
    local style = tonumber(getElementData(ped, "npc_social:style")) or 1
    local list = TALK_ANIMATIONS[role] or TALK_ANIMATIONS.listener

    return list[((style - 1) % #list) + 1]
end

local function playConversationAnimation(ped)
    local animation = getAnimation(ped)
    local key = animation[1] .. ":" .. animation[2]

    if lastAnimation[ped] ~= key then
        setPedAnimation(
            ped,
            animation[1],
            animation[2],
            -1,
            true,
            false,
            true,
            false,
            250,
            false
        )

        lastAnimation[ped] = key
    end
end

local function playGreetingAnimation(ped)
    local index = (getTickCount() % #GREETING_ANIMATIONS) + 1
    local animation = GREETING_ANIMATIONS[index]
    setPedAnimation(
        ped,
        animation[1],
        animation[2],
        -1,
        false,
        false,
        true,
        false,
        150,
        false
    )
end

local function clearConversationAnimation(ped)
    setPedAnimation(ped, false)
    lastAnimation[ped] = nil
end

addEventHandler("onClientElementDataChange", root, function(dataName)
    if dataName ~= "npc_social:state" then
        return
    end

    local state = getElementData(source, dataName)
    if state == "talk" then
        playConversationAnimation(source)
    elseif state == "greet" then
        playGreetingAnimation(source)
    else
        clearConversationAnimation(source)
    end
end)

addEventHandler("onClientPreRender", root, function()
    for _, ped in ipairs(getElementsByType("ped", root, true)) do
        local state = getElementData(ped, "npc_social:state")
        if state == "talk" or state == "greet" then
            stopPedMovement(ped)
            if state == "talk" then
                playConversationAnimation(ped)
            end

            local partner = getElementData(ped, "npc_social:partner")

            if isElement(partner) then
                local x, y = getElementPosition(ped)
                local px, py = getElementPosition(partner)
                setPedCameraRotation(
                    ped,
                    math.deg(math.atan2(px - x, py - y))
                )
            end
        end
    end
end)

addEventHandler("onClientPedDamage", root, function(attacker, weapon)
    outputDebugString(
        "[npc_hlc_social] onClientPedDamage ped="
        .. tostring(source)
        .. " attacker="
        .. tostring(attacker)
        .. " weapon="
        .. tostring(weapon),
        3
    )

    if attacker == localPlayer and isMeleeWeapon(weapon) then
        outputDebugString(
            "[npc_hlc_social] reporting melee hit to server",
            3
        )

        triggerServerEvent(
            "npc_social:onPlayerMeleeHit",
            resourceRoot,
            source,
            weapon
        )
    end
end)

addEventHandler("onClientElementDestroy", root, function()
    lastAnimation[source] = nil
end)
