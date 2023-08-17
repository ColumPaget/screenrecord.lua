-- display a countdown before starting recording, if the use requested that

function DoCountdown(count)
local i, str, S, perc

dialog=dialogs:progress("Recording Countdown")
dialog:set_max(count)
for i=0,count,1
do
	str=string.format("%d seconds", count-i)
	dialog:add(i, str)
	time.sleep(1)
end

dialog:close()
end

