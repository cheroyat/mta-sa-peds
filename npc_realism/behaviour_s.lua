local npc_hlc

local IDLE_CHANCE,FEAR_TIME
local IDLE_MIN,IDLE_MAX = 2500,6500
local IDLE_COOLDOWN = 45000

local ped_style = setmetatable({},{__mode = "k"})
local ped_speed = setmetatable({},{__mode = "k"})
local ped_lastidle = setmetatable({},{__mode = "k"})
local scared = setmetatable({},{__mode = "k"})

local IDLE_MALE = {
	{"ped","IDLE_stance",30},
	{"ped","IDLE_chat",20},
	{"ped","IDLE_HBHB",10},
	{"ped","phone_talk",15},
	{"SMOKING","M_smklean_loop",15},
	{"FOOD","EAT_Burger",5},
	{"ON_LOOKERS","point_loop",5}
}
local IDLE_FEMALE = {
	{"ped","WOMAN_idlestance",40},
	{"ped","IDLE_chat",20},
	{"ped","phone_talk",20},
	{"SMOKING","F_smklean_loop",15},
	{"ON_LOOKERS","point_loop",5}
}

local function readSettings()
	IDLE_CHANCE = tonumber(get("idle_chance")) or 0.05
	FEAR_TIME = tonumber(get("fear_time")) or 6000
end

addEventHandler("onResourceStart",resourceRoot,function()
	npc_hlc = getResourceFromName("npc_hlc")
	readSettings()
	setTimer(updateFear,500,0)
end)

local function pickIdle(model)
	local list = isFemaleSkin(model) and IDLE_FEMALE or IDLE_MALE
	local total = 0
	for _,e in ipairs(list) do total = total+e[3] end
	local pos = math.random()*total
	for _,e in ipairs(list) do
		pos = pos-e[3]
		if pos <= 0 then return e[1],e[2] end
	end
	return "ped","IDLE_stance"
end

-- called by npchlc_traffic on every walking ped it spawns
function initTrafficPed(ped)
	if not isElement(ped) then return false end
	local model = getElementModel(ped)
	local style,speed = getWalkStyleForSkin(model)
	setPedWalkingStyle(ped,style)
	ped_style[ped] = style
	ped_speed[ped] = speed
	if speed ~= "walk" then call(npc_hlc,"setNPCWalkSpeed",ped,speed) end
	ped_lastidle[ped] = getTickCount()-math.random(0,IDLE_COOLDOWN)
	return true
end

--------------------------------------------------
-- random idle stops
--------------------------------------------------

addEventHandler("npc_hlc:onNPCTaskDone",root,function(task)
	if task[1] ~= "walkAlongLine" and task[1] ~= "walkAroundBend" then return end
	local ped = source
	if not ped_style[ped] then return end
	if scared[ped] then return end
	if isPedInVehicle(ped) then return end

	local now = getTickCount()
	local last = ped_lastidle[ped] or 0
	if now-last < IDLE_COOLDOWN then return end
	if math.random() > IDLE_CHANCE then return end

	ped_lastidle[ped] = now
	local block,anim = pickIdle(getElementModel(ped))
	call(npc_hlc,"addNPCTask",ped,{"idle",math.random(IDLE_MIN,IDLE_MAX),block,anim})
end)

--------------------------------------------------
-- fear
--------------------------------------------------

local function skipIdleTask(ped)
	local thistask = getElementData(ped,"npc_hlc:thistask")
	if not thistask then return end
	local task = getElementData(ped,"npc_hlc:task.."..thistask)
	if task and task[1] == "idle" then
		setElementData(ped,"npc_hlc:thistask",thistask+1)
	end
end

function scarePed(ped,duration)
	if not isElement(ped) or not ped_style[ped] then return false end
	if isPedInVehicle(ped) or getElementHealth(ped) < 1 then return false end
	local until_tick = getTickCount()+(duration or FEAR_TIME)
	if not scared[ped] then
		call(npc_hlc,"setNPCWalkSpeed",ped,"sprint")
		setPedWalkingStyle(ped,0)
		skipIdleTask(ped)
	end
	scared[ped] = until_tick
	return true
end

function scarePedsAround(x,y,z,radius,duration)
	local count = 0
	for _,ped in ipairs(getElementsWithinRange(x,y,z,radius,"ped")) do
		if scarePed(ped,duration) then count = count+1 end
	end
	return count
end

function updateFear()
	local now = getTickCount()
	for ped,until_tick in pairs(scared) do
		if not isElement(ped) then
			scared[ped] = nil
		elseif now >= until_tick then
			scared[ped] = nil
			if isElement(ped) then
				setPedWalkingStyle(ped,ped_style[ped] or 0)
				call(npc_hlc,"setNPCWalkSpeed",ped,ped_speed[ped] or "walk")
			end
		end
	end
end

-- gunfire nearby
addEventHandler("onPlayerWeaponFire",root,function(weapon,endX,endY,endZ,hitElement,startX,startY,startZ)
	if weapon < 22 or weapon > 38 then return end
	local range = tonumber(get("shot_range")) or 32
	scarePedsAround(startX,startY,startZ,range)
	if endX then scarePedsAround(endX,endY,endZ,range*0.5) end
end)

-- someone dies in the street, everyone bolts
addEventHandler("onPedWasted",root,function()
	local x,y,z = getElementPosition(source)
	scarePedsAround(x,y,z,25,FEAR_TIME*1.5)
end)
addEventHandler("onPlayerWasted",root,function()
	local x,y,z = getElementPosition(source)
	scarePedsAround(x,y,z,25,FEAR_TIME*1.5)
end)

-- client reports a player aiming at peds
addEvent("npc_realism:aimedAt",true)
addEventHandler("npc_realism:aimedAt",root,function(peds)
	if type(peds) ~= "table" then return end
	if #peds > 24 then return end
	for _,ped in ipairs(peds) do
		if isElement(ped) and getElementType(ped) == "ped" then
			scarePed(ped)
		end
	end
end)