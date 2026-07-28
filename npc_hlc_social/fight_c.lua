local function facePartner(ped, partner)
    if not isElement(partner) then return end
    local x, y = getElementPosition(ped)
    local px, py = getElementPosition(partner)
    setPedCameraRotation(ped, math.deg(math.atan2(px - x, py - y)))
end

local function playFightAnimation(ped, partner)
    local tick = getTickCount()
    local attacker = math.floor(tick / 850) % 2 == 0
    local isFirst = tostring(ped) < tostring(partner)
    local attacking = attacker == isFirst

    if attacking then
        local attacks = { "fighta_1", "fighta_2", "fighta_3" }
        setPedAnimation(ped, "ped", attacks[(math.floor(tick / 850) % 3) + 1], 800, false, false, true, false, 100, false)
    else
        setPedAnimation(ped, "ped", "hit_front", 800, false, false, true, false, 100, false)
    end
end

addEventHandler("onClientPreRender", root, function()
    for _, ped in ipairs(getElementsByType("ped", root, true)) do
        if getElementData(ped, "npc_social:state") == "fight" then
            local partner = getElementData(ped, "npc_social:partner")
            if isElement(partner) then
                setPedControlState(ped, "forwards", false)
                setPedControlState(ped, "walk", false)
                setPedControlState(ped, "sprint", false)
                facePartner(ped, partner)
                playFightAnimation(ped, partner)
            end
        end
    end
end)
