local event = Event()
function event.onTargetCombat(self, target)
    if not self then
        return true
    end
    return true
end

event:register()