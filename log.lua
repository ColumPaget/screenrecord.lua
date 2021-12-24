

function ProcessLogInit()
local log={}

log.lines={}

log.add=function(self, str)
local i

for i=1,10,1
do
	if log.lines[i+1] ~= nil then log.lines[i]=log.lines[i+1] end
	log.lines[10]=str
end

end


log.display=function(self)
local i, gui
local str=""

gui=dialogs:log("Error Report: ffmpeg exited. last lines were...", 600, 400)
for i=1,10,1
do
	gui:add(log.lines[i])
end

end

return log
end
