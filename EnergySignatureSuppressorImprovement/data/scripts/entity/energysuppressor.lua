
function EnergySuppressor.updateServer(timeStep)
    self.data.time = self.data.time - timeStep

    if self.data.time <= 0 then
        local x, y = Sector():getCoordinates()
        getParentFaction():sendChatMessage("Energy Signature Suppressor"%_T, ChatMessageType.Normal, [[Your energy signature suppressor in sector \s(%1%:%2%) has burnt out!]]%_T, x, y)
        getParentFaction():sendChatMessage("Energy Signature Suppressor"%_T, ChatMessageType.Warning, [[Your energy signature suppressor in sector \s(%1%:%2%) has burnt out!]]%_T, x, y)

        local entity = Entity()
        entity:clearValues() -- allow things to spawn in
        entity:destroy(entity.id) -- self-destruct
        --print("an energy suppressor has burnt out in:", x, y)
        terminate()
    end
end