local TimerEvent = class "TimerEvent"

function TimerEvent:init(time, fn)
	self.lifetime = time
	self.timerCallback = fn
end

function TimerEvent:onLifeover()
	self.timerCallback()
end

return TimerEvent
