local SCAN_MS = 300
local AIM_RANGE = 25
local AIM_SPREAD = 5
local RESEND_MS = 2500
local MAX_BATCH = 24

local notified = setmetatable({},{__mode = "k"})

local function isThreatening()
	local weapon = getPedWeapon(localPlayer)
	if not weapon or weapon < 22 or weapon > 38 then return false end
	if isPedDead(localPlayer) or isPedInVehicle(localPlayer) then return false end
	return getPedControlState("aim_weapon") or getPedControlState("fire")
end

local function scanAim()
	if not isThreatening() then return end

	local hx,hy,hz = getPedTargetCollision(localPlayer)
	if not hx then hx,hy,hz = getPedTargetEnd(localPlayer) end
	if not hx then return end

	local px,py,pz = getElementPosition(localPlayer)
	local dist = getDistanceBetweenPoints3D(px,py,pz,hx,hy,hz)
	if dist > AIM_RANGE and dist > 0 then
		local f = AIM_RANGE/dist
		hx,hy,hz = px+(hx-px)*f,py+(hy-py)*f,pz+(hz-pz)*f
	end

	local now = getTickCount()
	local batch = {}
	for _,ped in ipairs(getElementsWithinRange(hx,hy,hz,AIM_SPREAD,"ped")) do
		if getElementData(ped,"npc_hlc") and not isPedInVehicle(ped) and getElementHealth(ped) > 0 then
			if not notified[ped] or now-notified[ped] > RESEND_MS then
				notified[ped] = now
				batch[#batch+1] = ped
				if #batch >= MAX_BATCH then break end
			end
		end
	end

	if #batch > 0 then
		triggerServerEvent("npc_realism:aimedAt",resourceRoot,batch)
	end
end

addEventHandler("onClientResourceStart",resourceRoot,function()
	setTimer(scanAim,SCAN_MS,0)
end)