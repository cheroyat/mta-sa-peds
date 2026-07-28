-- steering_c.lua
-- Load after actions_c.lua

STEER = {
    enabled = true,

    radius = 0.42,
    playerRadius = 0.62,
    vehicleRadius = 2.4,

    scanRange = 9.0,
    horizon = 2.5,
    avoid = 1.65,

    turnRate = 260,
    feeler = 3.2,
    feelerAngle = 38,
    feelerPower = 2.2,

    slowDist = 2.0,
    stopDist = 0.55,

    heavyHz = 10,
    heavyBudget = 12,

    stuckTime = 1800,
    giveUpTime = 8000,

    vehicleLookAhead = 6.0,
    vehicleSideStep = 2.8,
    vehiclePassTime = 1800
}

local SPEED = {
    walk = 1.5559,
    run = 5.706,
    sprint = 9.562,
    sprintfast = 12.281
}

local rawWalkToPos = makeNPCWalkToPos
local brain = setmetatable({}, { __mode = "k" })

local lastFrame = getTickCount()
local frameDt = 0.016
local heavyDone = 0

local function norm2(x, y)
    local length = math.sqrt(x * x + y * y)

    if length < 0.0001 then
        return 0, 0, 0
    end

    return x / length, y / length, length
end

local function angleDifference(a, b)
    return (b - a + 180) % 360 - 180
end

local function resetFrame()
    local now = getTickCount()

    frameDt = math.min((now - lastFrame) * 0.001, 0.1)
    lastFrame = now
    heavyDone = 0
end

addEventHandler("onClientPreRender", root, resetFrame, false, "high")

local function getState(ped)
    local state = brain[ped]

    if state then
        return state
    end

    local x, y = getElementPosition(ped)

    state = {
        head = -getPedRotation(ped),

        ax = 0,
        ay = 0,
        cap = "full",

        vx = 0,
        vy = 0,

        px = x,
        py = y,
        pt = getTickCount(),

        anchorX = x,
        anchorY = y,
        anchorTime = getTickCount(),

        nextHeavy = getTickCount() + math.random(0, 100),

        bias = math.random(2) == 1 and 1 or -1,

        vehicleSide = nil,
        vehicleUntil = 0
    }

    brain[ped] = state

    return state
end

local function isVehicleBlocked(ped, vehicle)
    if not isElement(vehicle) then
        return false
    end

    if not isElementCollidableWith(ped, vehicle) then
        return false
    end

    return true
end

local function getVehicleRadius(vehicle)
    local x1, y1 = getElementBoundingBox(vehicle)

    if not x1 or not y1 then
        return STEER.vehicleRadius
    end

    return math.max(math.abs(x1), math.abs(y1), 1.8) + 0.5
end

local function sideIsFree(ped, x, y, z, sideX, sideY, distance)
    local targetX = x + sideX * distance
    local targetY = y + sideY * distance

    return isLineOfSightClear(
        x,
        y,
        z + 0.35,
        targetX,
        targetY,
        z + 0.35,
        true,
        true,
        true,
        true,
        false,
        false,
        false,
        ped
    )
end

local function chooseVehicleSide(ped, state, x, y, z, rightX, rightY)
    local now = getTickCount()

    if state.vehicleSide and now < state.vehicleUntil then
        return state.vehicleSide
    end

    local rightFree = sideIsFree(
        ped,
        x,
        y,
        z,
        rightX,
        rightY,
        STEER.vehicleSideStep
    )

    local leftFree = sideIsFree(
        ped,
        x,
        y,
        z,
        -rightX,
        -rightY,
        STEER.vehicleSideStep
    )

    if rightFree and not leftFree then
        state.vehicleSide = 1
    elseif leftFree and not rightFree then
        state.vehicleSide = -1
    elseif rightFree and leftFree then
        state.vehicleSide = state.bias
    else
        state.vehicleSide = nil
    end

    state.vehicleUntil = now + STEER.vehiclePassTime

    return state.vehicleSide
end

local function considerPed(ped, state, other, otherRadius)
    if other == ped or not isElement(other) then
        return
    end

    local x, y, z = getElementPosition(ped)
    local ox, oy, oz = getElementPosition(other)

    if math.abs(oz - z) > 2.0 then
        return
    end

    local dx, dy = ox - x, oy - y
    local distance = math.sqrt(dx * dx + dy * dy)

    if distance < 0.01 then
        return
    end

    local fx = math.sin(math.rad(state.head))
    local fy = math.cos(math.rad(state.head))
    local rightX = fy
    local rightY = -fx

    local combinedRadius = STEER.radius + otherRadius + 0.2
    local forwardDistance = dx * fx + dy * fy
    local sideDistance = dx * rightX + dy * rightY

    local otherVx, otherVy = 0, 0

    if getElementType(other) == "vehicle" then
        otherVx, otherVy = getElementVelocity(other)
        otherVx, otherVy = otherVx * 50, otherVy * 50
    else
        local otherState = brain[other]

        if otherState then
            otherVx, otherVy = otherState.vx, otherState.vy
        else
            otherVx, otherVy = getElementVelocity(other)
            otherVx, otherVy = otherVx * 50, otherVy * 50
        end
    end

    local isVehicle = getElementType(other) == "vehicle"

    if isVehicle and forwardDistance > 0 and
        forwardDistance < STEER.vehicleLookAhead and
        math.abs(sideDistance) < otherRadius then

        local side = chooseVehicleSide(
            ped,
            state,
            x,
            y,
            z,
            rightX,
            rightY
        )

        if side then
            local strength =
                (1 - forwardDistance / STEER.vehicleLookAhead) * 3.8

            state.ax = state.ax + rightX * side * strength
            state.ay = state.ay + rightY * side * strength

            if forwardDistance < STEER.slowDist then
                state.cap = "walk"
            end

            if forwardDistance < STEER.stopDist and
                not sideIsFree(
                    ped,
                    x,
                    y,
                    z,
                    rightX * side,
                    rightY * side,
                    STEER.vehicleSideStep
                )
            then
                state.cap = "stop"
            end
        end

        return
    end

    if distance < combinedRadius then
        local push = (combinedRadius - distance) / combinedRadius * 3.0

        state.ax = state.ax - dx / distance * push
        state.ay = state.ay - dy / distance * push
    end

    local relativeVx = state.vx - otherVx
    local relativeVy = state.vy - otherVy
    local relativeSpeed =
        relativeVx * relativeVx + relativeVy * relativeVy

    if relativeSpeed < 0.04 then
        return
    end

    local timeToClosest =
        (dx * relativeVx + dy * relativeVy) / relativeSpeed

    if timeToClosest <= 0 or timeToClosest > STEER.horizon then
        return
    end

    local closestX = dx - relativeVx * timeToClosest
    local closestY = dy - relativeVy * timeToClosest
    local closestDistance =
        math.sqrt(closestX * closestX + closestY * closestY)

    if closestDistance > combinedRadius then
        return
    end

    local passSide = sideDistance >= 0 and -1 or 1

    local otherForwardSpeed = otherVx * fx + otherVy * fy
    local myForwardSpeed = state.vx * fx + state.vy * fy

    local headOn =
        otherForwardSpeed < -0.25 and myForwardSpeed > 0.25

    if headOn and math.abs(sideDistance) < combinedRadius * 1.5 then
        passSide = 1
    end

    local strength =
        (1 - timeToClosest / STEER.horizon) *
        (1 - closestDistance / combinedRadius) *
        STEER.avoid

    state.ax = state.ax + rightX * passSide * strength
    state.ay = state.ay + rightY * passSide * strength

    if forwardDistance > 0 and math.abs(sideDistance) < combinedRadius * 1.4 then
        if distance < STEER.stopDist then
            state.cap = "stop"
        elseif distance < STEER.slowDist then
            state.cap = "walk"
        end
    end
end

local function updateAvoidance(ped, state, now)
    local x, y, z = getElementPosition(ped)

    local elapsed = (now - state.pt) * 0.001

    if elapsed > 0.05 then
        state.vx = (x - state.px) / elapsed
        state.vy = (y - state.py) / elapsed

        state.px = x
        state.py = y
        state.pt = now
    end

    local forwardX = math.sin(math.rad(state.head))
    local forwardY = math.cos(math.rad(state.head))
    local rightX = forwardY
    local rightY = -forwardX

    state.ax = state.ax * 0.35
    state.ay = state.ay * 0.35
    state.cap = "full"

    local interior = getElementInterior(ped)
    local dimension = getElementDimension(ped)

    for _, other in ipairs(
        getElementsWithinRange(
            x,
            y,
            z,
            STEER.scanRange,
            "ped",
            interior,
            dimension
        )
    ) do
        considerPed(ped, state, other, STEER.radius)
    end

    for _, other in ipairs(
        getElementsWithinRange(
            x,
            y,
            z,
            STEER.scanRange,
            "player",
            interior,
            dimension
        )
    ) do
        considerPed(ped, state, other, STEER.playerRadius)
    end

    for _, vehicle in ipairs(
        getElementsWithinRange(
            x,
            y,
            z,
            STEER.scanRange,
            "vehicle",
            interior,
            dimension
        )
    ) do
        if isVehicleBlocked(ped, vehicle) then
            considerPed(
                ped,
                state,
                vehicle,
                getVehicleRadius(vehicle)
            )
        end
    end

    local goalX = state.ax + forwardX
    local goalY = state.ay + forwardY
    local _, _, goalLength = norm2(goalX, goalY)

    if goalLength < 0.1 then
        goalX = forwardX
        goalY = forwardY
    end

    state.ax = goalX - forwardX
    state.ay = goalY - forwardY

    if math.abs(state.ax) < 0.1 and math.abs(state.ay) < 0.1 then
        state.vehicleSide = nil
    end

    if getDistanceBetweenPoints2D(
        x,
        y,
        state.anchorX,
        state.anchorY
    ) > 0.65 then
        state.anchorX = x
        state.anchorY = y
        state.anchorTime = now
    elseif state.cap ~= "stop" then
        local stuckFor = now - state.anchorTime

        if stuckFor > STEER.giveUpTime then
            state.vehicleSide = nil
            state.bias = -state.bias
            state.anchorTime = now
        elseif stuckFor > STEER.stuckTime then
            state.ax = rightX * state.bias * 2.4
            state.ay = rightY * state.bias * 2.4
            state.cap = "full"
        end
    end
end

function makeNPCWalkToPos(npc, x, y)
    if not STEER.enabled then
        return rawWalkToPos(npc, x, y)
    end

    local state = getState(npc)
    local now = getTickCount()

    if now >= state.nextHeavy and heavyDone < STEER.heavyBudget then
        updateAvoidance(npc, state, now)

        state.nextHeavy = now + 1000 / STEER.heavyHz
        heavyDone = heavyDone + 1
    end

    local pedX, pedY = getElementPosition(npc)
    local desiredX, desiredY = norm2(x - pedX, y - pedY)

    local steerX = desiredX + state.ax
    local steerY = desiredY + state.ay

    steerX, steerY = norm2(steerX, steerY)

    if steerX == 0 and steerY == 0 then
        steerX = math.sin(math.rad(state.head))
        steerY = math.cos(math.rad(state.head))
    end

    local wantedAngle = math.deg(math.atan2(steerX, steerY))
    local turn = angleDifference(state.head, wantedAngle)
    local maxTurn = STEER.turnRate * frameDt

    turn = math.max(-maxTurn, math.min(maxTurn, turn))
    state.head = (state.head + turn) % 360

    setPedCameraRotation(npc, state.head)

    if state.cap == "stop" then
        stopNPCWalkingActions(npc)
        return
    end

    local speed = getNPCWalkSpeed(npc)

    if state.cap == "walk" or math.abs(turn) > 105 then
        speed = "walk"
    end

    setPedControlState(npc, "forwards", true)
    setPedControlState(npc, "walk", speed == "walk")

    setPedControlState(
        npc,
        "sprint",
        speed == "sprint" or
        speed == "sprintfast" and
        not getPedControlState(npc, "sprint")
    )
end
