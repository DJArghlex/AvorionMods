-- this adds the "deleteonplayersleft" script to all the temporary defenders in a sector, which should hopefully prevent warzone sectors ballooning out of control and causing problems.

-- namespace TemporaryDefender

if onServer() then

local oldInitialize = TemporaryDefender.initialize
function TemporaryDefender.initialize()
    local entity = Entity()
    entity:addScriptOnce("entity/deleteonplayersleft.lua")
    oldInitialize()
end

end