MOVE = {
	DEFAULT = 0,PLAYER = 54,PLAYER_FAT = 55,PLAYER_MUSCULAR = 56,
	MAN = 118,SHUFFLE = 119,OLDMAN = 120,GANG1 = 121,GANG2 = 122,
	OLDFATMAN = 123,FATMAN = 124,JOGGER = 125,DRUNKMAN = 126,BLINDMAN = 127,
	SWAT = 128,WOMAN = 129,SHOPPING = 130,BUSYWOMAN = 131,SEXYWOMAN = 132,
	PRO = 133,OLDWOMAN = 134,FATWOMAN = 135,JOGWOMAN = 136,OLDFATWOMAN = 137,
	SKATE = 138
}

-- model names encode race/gender/age/role, so we classify instead of hand-mapping 250 skins
SKIN_NAME = { [0] = "cj", "truth", "maccer", "cdeput", "sfpdm1", "bb", "wfycrp", "male01", "wmycd2", "bfori", "bfost", "vbfycrp", "bfyri", "bfyst", "bmori", "bmost", "bmyap", "bmybu", "bmybe", "bmydj", "bmyri", "bmycr", "bmyst", "wmybmx", "wbdyg1", "wbdyg2", "wmybp", "wmycon", "bmydrug", "wmydrug", "hmydrug", "dwfolc", "dwmolc1", "dwmolc2", "dwmylc1", "hmogar", "wmygol1", "wmygol2", "hfori", "hfost", "hfyri", "hfyst", "suzie", "hmori", "hmost", "hmybe", "hmyri", "hmycr", "hmyst", "omokung", "wmymech", "bmymoun", "wmymoun", "ofori", "ofost", "ofyri", "ofyst", "omori", "omost", "omyri", "omyst", "wmyplt", "wmopj", "bfypro", "hfypro", "vwmyap", "bmypol1", "bmypol2", "wmoprea", "sbfyst", "wmosci", "wmysgrd", "swmyhp1", "swmyhp2", "", "swfopro", "wfystew", "swmotr1", "wmotr1", "bmotr1", "vbmybox", "vwmybox", "vhmyelv", "vbmyelv", "vimyelv", "vwfypro", "vhfyst", "vwfyst1", "wfori", "wfost", "wfyjg", "wfyri", "wfyro", "wfyst", "wmori", "wmost", "wmyjg", "wmylg", "wmyri", "wmyro", "wmycr", "wmyst", "ballas1", "ballas2", "ballas3", "fam1", "fam2", "fam3", "lsv1", "lsv2", "lsv3", "maffa", "maffb", "mafboss", "vla1", "vla2", "vla3", "triada", "triadb", "lvpdm1", "triboss", "dnb1", "dnb2", "dnb3", "vmaff1", "vmaff2", "vmaff3", "vmaff4", "dnmylc", "dnfolc1", "dnfolc2", "dnfylc", "dnmolc1", "dnmolc2", "sbmotr2", "swmotr2", "sbmytr3", "swmotr3", "wfybe", "bfybe", "hfybe", "sofybu", "sbmyst", "sbmycr", "bmycg", "wfycrk", "hmycm", "wmybu", "bfybu", "", "wfybu", "dwfylc1", "wfypro", "wmyconb", "wmybe", "wmypizz", "bmobar", "cwfyhb", "cwmofr", "cwmohb1", "cwmohb2", "cwmyfr", "cwmyhb1", "bmyboun", "wmyboun", "wmomib", "bmymib", "wmybell", "bmochil", "sofyri", "somyst", "vwmybjd", "vwfycrp", "sfr1", "sfr2", "sfr3", "bmybar", "wmybar", "wfysex", "wmyammo", "bmytatt", "vwmycr", "vbmocd", "vbmycr", "vhmycr", "sbmyri", "somyri", "somybu", "swmyst", "wmyva", "copgrl3", "gungrl3", "mecgrl3", "nurgrl3", "crogrl3", "gangrl3", "cwfofr", "cwfohb", "cwfyfr1", "cwfyfr2", "cwmyhb2", "dwfylc2", "dwmylc2", "omykara", "wmykara", "wfyburg", "vwmycd", "vhfypro", "", "omonood", "omoboat", "wfyclot", "vwmotr1", "vwmotr2", "vwfywai", "sbfori", "swfyri", "wmyclot", "sbfost", "sbfyri", "sbmocd", "sbmori", "sbmost", "shmycr", "sofori", "sofost", "sofyst", "somobu", "somori", "somost", "swmotr5", "swfori", "swfost", "swfyst", "swmocd", "swmori", "swmost", "shfypro", "sbfypro", "swmotr4", "swmyri", "smyst", "smyst2", "sfypro", "vbfyst2", "vbfypro", "vhfyst3", "bikera", "bikerb", "bmypimp", "swmycr", "wfylg", "wmyva2", "bmosec", "bikdrug", "wmych", "sbfystr", "swfystr", "heck1", "heck2", "bmycon", "wmycd1", "bmocd", "vwfywa2", "wmoice" }

-- gangs: ballas, grove, vagos, aztecas, rifa, da nang, bikers, dealers, pimps
GANG_SKINS = {
	[102]=1,[103]=1,[104]=1, [105]=1,[106]=1,[107]=1,
	[108]=1,[109]=1,[110]=1, [114]=1,[115]=1,[116]=1,
	[173]=1,[174]=1,[175]=1, [121]=1,[122]=1,[123]=1,
	[247]=1,[248]=1,[254]=1, [28]=1,[29]=1,[30]=1,
	[249]=1,[180]=1,[144]=1
}
-- mafia / triads / suits: walk like they own the block
MAFIA_SKINS = {
	[111]=1,[112]=1,[113]=1, [124]=1,[125]=1,[126]=1,[127]=1,
	[117]=1,[118]=1,[120]=1, [165]=1,[166]=1
}
COP_SKINS = {
	[71]=1,[163]=1,[164]=1,[253]=1,[280]=1,[281]=1,[282]=1,
	[283]=1,[284]=1,[285]=1,[286]=1,[287]=1,[288]=1,[66]=1,[67]=1
}
-- tune these two to taste, they're the only judgement calls in here
FAT_SKINS = {
	[35]=1,[49]=1,[78]=1,[79]=1,[134]=1,[135]=1,[137]=1,
	[156]=1,[168]=1,[209]=1,[210]=1,[227]=1,[264]=1,[176]=1,[177]=1
}
BUM_SKINS = { [62]=1,[145]=1,[132]=1,[133]=1,[128]=1,[129]=1,[130]=1,[131]=1 }

local function pickWeighted(t)
	local total = 0
	for _,e in ipairs(t) do total = total+e[2] end
	local pos = math.random()*total
	for _,e in ipairs(t) do
		pos = pos-e[2]
		if pos <= 0 then return e[1] end
	end
	return t[1][1]
end

local MALE_CASUAL = {{118,60},{0,25},{54,15}}
local FEMALE_CASUAL = {{129,70},{130,30}}

-- returns style, walkspeed
function getWalkStyleForSkin(model)
	local name = SKIN_NAME[model] or ""

	if COP_SKINS[model] then return MOVE.SWAT,"walk" end
	if GANG_SKINS[model] then return math.random(2) == 1 and MOVE.GANG1 or MOVE.GANG2,"walk" end
	if MAFIA_SKINS[model] then return MOVE.PRO,"walk" end
	if BUM_SKINS[model] then
		return pickWeighted({{MOVE.DRUNKMAN,50},{MOVE.SHUFFLE,35},{MOVE.BLINDMAN,15}}),"walk"
	end

	local gender,age = name:match("([fm])([yo])")
	gender = gender or "m"
	age = age or "y"

	local fat = FAT_SKINS[model]
	local role =
		name:find("pro") and "pro" or
		name:find("sex") and "pro" or
		name:find("jg") and "jog" or
		name:find("crk") and "crack" or
		name:match("bu%d?$") and "biz" or
		name:match("ri%d?$") and "rich" or
		name:find("bp") and "biz" or
		"street"

	if gender == "f" then
		if age == "o" then return fat and MOVE.OLDFATWOMAN or MOVE.OLDWOMAN,"walk" end
		if role == "pro" then return MOVE.SEXYWOMAN,"walk" end
		if role == "jog" then return MOVE.JOGWOMAN,"run" end
		if role == "crack" then return MOVE.SHUFFLE,"walk" end
		if role == "biz" or role == "rich" then return MOVE.BUSYWOMAN,"walk" end
		if fat then return MOVE.FATWOMAN,"walk" end
		return pickWeighted(FEMALE_CASUAL),"walk"
	end

	if age == "o" then return fat and MOVE.OLDFATMAN or MOVE.OLDMAN,"walk" end
	if role == "jog" then return MOVE.JOGGER,"run" end
	if role == "biz" or role == "rich" then return MOVE.PRO,"walk" end
	if fat then return MOVE.FATMAN,"walk" end
	return pickWeighted(MALE_CASUAL),"walk"
end

function isFemaleSkin(model)
	local name = SKIN_NAME[model] or ""
	local gender = name:match("([fm])[yo]")
	return gender == "f"
end