local function isMeleeWeapon(weapon)
    weapon = tonumber(weapon)
    return weapon == 0
        or (weapon >= 1 and weapon <= 8)
        or (weapon >= 10 and weapon <= 14)
end

local lastAttack = setmetatable({}, { __mode = "k" })

local function stopMovement(ped)
    setPedControlState(ped, "forwards", false)
    setPedControlState(ped, "walk", false)
    setPedControlState(ped, "sprint", false)
    setPedControlState(ped, "fire", false)
    setPedControlState(ped, "aim_weapon", false)
end

local function faceTarget(ped, target)
    local x, y = getElementPosition(ped)
    local tx, ty = getElementPosition(target)
    setPedCameraRotation(ped, math.deg(math.atan2(tx - x, ty - y)))
end

local function animateAttack(ped, now)
    if (lastAttack[ped] or 0) > now then return end
    local attacks = { "fighta_1", "fighta_2", "fighta_3" }
    setPedAnimation(ped, "ped", attacks[(math.floor(now / 700) % 3) + 1],
        650, false, false, true, false, 100, false)
    lastAttack[ped] = now + 600
end

addEventHandler("onClientPreRender", root, function()
    local now = getTickCount()
    for _, ped in ipairs(getElementsByType("ped", root, true)) do
        if getElementData(ped, "npc_social:state") == "retaliate" then
            local target = getElementData(ped, "npc_social:partner")
            if isElement(target) then
                stopMovement(ped)
                faceTarget(ped, target)
                local x, y, z = getElementPosition(ped)
                local tx, ty, tz = getElementPosition(target)
                if getDistanceBetweenPoints3D(x, y, z, tx, ty, tz) > 1.7 then
                    setPedControlState(ped, "forwards", true)
                else
                    animateAttack(ped, now)
                end
            end
        end
    end
end)
