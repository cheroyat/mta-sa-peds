function changeDensity(player,cmdname,trtype,density)
	if not trtype and not density then
		outputChatBox("Digite: /density [numero] ",player)
		return
	end
	if exports.npchlc_traffic:setTrafficDensity(trtype,density) then
		if density then
			local prevden = exports.npchlc_traffic:getTrafficDensity(trtype)
			outputChatBox(trtype.." densidade de tráfego mudou de "..prevden.." para "..density)
		else
			outputChatBox("toda a densidade de tráfego mudou para "..trtype)
		end
	end
end
addCommandHandler("density",changeDensity)

