-- rglx's emergency behemoth neutralizer patch
-- prevents behemoth scripts from simply DELETING everything present and requiring the behemoth to have the sector loaded to actually destroy everything present

-- boxelware should not have done it like this.

-- leave this here. tells the avorion engine which script namespace to load this into.
-- namespace SpawnBehemoth

function SpawnBehemoth.finish()

    local sector = Sector()
    local behemoth = sector:getEntitiesByScriptValue("behemoth_boss")
    if not behemoth then
        -- exit this script and unload it if it's already dead or missing
        terminate()
        return
    end

    -- if it's still there, hyperjump it away
    sector:deleteEntityJumped(behemoth)

    -- this is where the code used to delete everything present in the sector and make wreckages of it, which leads to broken gates as well.
    local message = self.getFinishMessage(data.quadrant)

    -- code resumes as normal, notifying the online playerbase of the behemoth moving out of the sector. also make a log entry for this.
    local x, y = sector:getCoordinates()
    print("rglx_ServerLib_OfflineBehemothNeutralizer: prevented the erasure of ("..x..":"..y..") by the local Behemoth.")
    Server():broadcastChatMessage("", ChatMessageType.Warning, message, x, y)

    terminate()
end

--print("rglx_ServerLib_OfflineBehemothNeutralizer: behemoths will no longer delete NPC sectors.")