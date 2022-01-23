package.path = package.path .. ";data/scripts/lib/?.lua"

commandName = "/report"
commandDescription = "Reports an issue to the administration team. Be specific!"
commandHelp = "[server/mod/player] [what's wrong]"

-- remove laserzwei's broken command
initialize = nil
analyzeReport = nil

local minimumTimeBetweenReports = 240  -- in seconds

function getDescription()
	return commandDescription
end

function getHelp()
	return commandDescription .. " Usage: " .. commandName .. " " .. commandHelp
end


function execute(sender, commandName, ...)
	local args = {...}
	local player = Player()
	local returnValue = "Please be more specific!"

	-- forbid client execution
	if onClient() then
		return 1, "Execution on client forbidden.", "Execution on client forbidden."
	end
	
	-- basic sanity checking
	if args[1] == nil or args[2] == nil then
		return 1, returnValue, returnValue
	end

	local server = Server()
	local x, y = Sector():getCoordinates()
	
	local lastReportSentTime = player:getValue("reportTimestamp") or 0
	if lastReportSentTime > server.runtime - minimumTimeBetweenReports then
		returnValue = "Report not sent. You have to wait " .. minimumTimeBetweenReports .. " seconds between reports."
		return 1, returnValue, returnValue
	end

	local reasonText = ""
	for id,snippet in ipairs(args) do
		if id ~= 1 then
			reasonText = reasonText.." "..snippet
		end
	end

	-- reset player's timer
	player:setValue("reportTimestamp", server.runtime)

	local reportLine = "[" .. os.date("%Y-%m-%d %X") .. "] [/report from " .. player.name .. "{" .. player.id.id .. "}]  location: ("..x..":"..y..")  target: "..args[1].."  about: " .. reasonText
	-- print to the log
	printlog(reportLine)

	print("/report: report logged to main game log!")

	-- print to the reports file
	local reportsFile = server.folder .. "/player-reports.log" -- location to additionally log reports
	reportsFileHandle = io.open(reportsFile,"a+")
	if reportsFileHandle ~= nil then
		reportsFileHandle:write(reportLine .. "\n")
		io.close(reportsFileHandle)
	end

	print("/report: report logged into separate file: "..reportsFile)

	local allPlayers = { server:getPlayers() } -- table wrapped to make it nice and iteratable

	for key, playerObject in pairs(allPlayers) do
		if server:hasAdminPrivileges(playerObject) then
			print("/report: notifying ".. player.name .. " of report")
			if server:isOnline(playerObject.id) then
				playerObject:sendChatMessage("/report from ".. player.name,2,"A player has reported something to you! ("..x..":"..y..")")
				--playerObject:sendChatMessage("/report from " .. player.name,0,"location: ("..x..":"..y..")\n  target: "..args[1].."\n  about: " .. reasonText)
			end
			local outgoingMail = Mail()
			outgoingMail.sender = player.name .. " (via /report)"
			outgoingMail.header = "Report via /report"
			outgoingMail.text = "A player has reported something to you!\nLocation: ("..x..":"..y..")\n\nSubject: "..args[1].."\n\n" .. reasonText
			playerObject:addMail(outgoingMail)
		end
	end
	return 0
end