-- Display the dialog that asks for all the recording settings

function RecordDialogCopyChoicesToConfig(config, choices)
local name, value

if choices == nil then return nil end
for name,value in pairs(choices)
do
	if value ~= nil
	then
		name=string.gsub(name, ' ', '_')
		config[name]=value
	end
end

return config
end


function RecordDialogSetup(config, devices)
local str, S, toks, tok, device

form=dialogs:form("setup screen recording")

form:addchoice("audio", sound:list(), "(select audio input or 'none')", sound:get_formatted(config.audio))
form:addchoice("fps", "1|2|5|10|15|25|30|45|60", "(video frames per second)", config.fps)
form:addchoice("size", GetScreenResolution().."|1024x768|800x600|640x480|no video", "(area of screen to capture)", config.size)
form:addchoice("codec", codecs:list(), "(codec)", codecs:get_title(config.codec))
form:addchoice("follow mouse", "no|edge|centered", "(capture region moves with mouse)")
form:addboolean("hide pointer", "(don't show mouse pointer on screen)", config.hide_pointer)
form:addboolean("show capture region", "(draw outline of capture region on screen)", config.show_region)
form:addboolean("noise reduction", "(if audio, apply noise filters)", config.noise_reduction)
form:addentry("countdown", "(seconds of gracetime before recording)")

return RecordDialogCopyChoicesToConfig(config, form:run())
end


