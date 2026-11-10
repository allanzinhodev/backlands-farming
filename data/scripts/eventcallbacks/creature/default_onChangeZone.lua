local event = Event()

function event.onChangeZone(self, fromZone, toZone)
    if not self or not self:isPlayer() then
        return false
    end
    return false
end

event:register(-1)