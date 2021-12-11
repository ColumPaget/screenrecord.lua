





function GetScreenResolution()
local S
local dim=""

S=stream.STREAM("cmd:xdpyinfo");
str=S:readln()
while str ~= nil
do
	str=strutil.trim(str)	
	toks=strutil.TOKENIZER(str, "\\S")
	tok=toks:next()
	if tok=="dimensions:"
	then 
		dim=toks:next()
	end
	str=S:readln()
end
S:close()

return dim
end



function CopyChoicesToConfig(config, choices)
local name, value

if choices == nil then return nil end
for name,value in pairs(choices)
do
	if value ~= nil
	then
		if name == "output path" then config["output_path"] = value
		elseif name == "follow mouse" then config["follow_mouse"] = value
		else config[name]=value
		end
	end
end

return config
end


function SetupDialog(config, devices)
local str, S, toks, tok, device

form=dialogs:form("setup screen recording")

str="none"
for i,device in ipairs(devices)
do
	str=str .. "|" .. device.type .. ":" .. device.num..":"..device.name
	if device.channels==1
	then
		str=str..":mono"
	else
		str=str..":stereo"
	end
end

form:addchoice("audio", str, "(select audio input or 'none')")
form:addchoice("fps", "1|2|5|10|15|25|30|45|60", "(video frames per second)", config.fps)
form:addchoice("size", GetScreenResolution().."|1024x768|800x600|640x480|no video", "(area of screen to capture)", config.size)
form:addchoice("codec", codecs:list(), "(codec)", config.codec)
form:addchoice("follow mouse", "no|edge|centered", "(capture region moves with mouse)")
form:addboolean("show capture region", "(draw outline of capture region on screen)")
form:addboolean("noise reduction", "(if audio, apply noise filters)")
form:addentry("countdown", "(seconds of gracetime before recording)")

return CopyChoicesToConfig(config, form:run())
end



function DoCountdown(count)
local i, str, S, perc

dialog=dialogs:progress("recording in:", count, true)
for i=0,count,1
do
	dialog:add(i, i)
	time.sleep(1)
end

end



function AudioRecordDialog()
local dialog={}

dialog=QarmaProgressDialog("level:", 100)
dialog.add_level=dialog.add

dialog.add=function(self, str)
local toks, tok
local dB=0

toks=strutil.TOKENIZER(str, " ")
tok=toks:next()
while tok ~= nil
do
if tok=="M:" then dB=tonumber(toks:next()) end
tok=toks:next()
end

self:add_level(100 + dB)

end

return(dialog)
end





function BuildAudioConfig(config)
local toks, tok, audio_type, str, channels, devnum="0"
local audio=""
local audio_filter=""

	toks=strutil.TOKENIZER(config.audio, ":")
	audio_type=toks:next()
	devnum=toks:next()
	devname=toks:next()
	str=toks:next()
	if str=="mono"
	then
		channels="1"
	else
		channels="2"
	end


	if audio_type == "alsa"
	then
		audio="-f " .. audio_type .. " -thread_queue_size 1024 -ac ".. channels .. " -i hw:" .. devnum.." "
	elseif audio_type == "oss"
	then
		audio="-f " .. audio_type .. " -thread_queue_size 1024 -ac ".. channels .. " -i " .. devname.." "
	end

	if config["noise reduction"] == true then audio_filter="-af highpass=f=200,lowpass=f=3000 " end

	return audio, audio_filter
end





function DoRecord(config)
local audio=""
local audio_filter=""
local show_pointer=""
local show_region=""
local follow_mouse=""
local audio=""
local audio_filter=""
local cmdS, S, poll, dialog, str, Xdisplay, codec
local gui

Xdisplay=process.getenv("DISPLAY") .. " "
if config.audio ~= "none" then audio,audio_filter=BuildAudioConfig(config) end

if config["show capture region"] == true then show_region="-show_region 1 " end
--if config["show pointer"] == false then show_pointer="-draw_mouse 0 " end

if config["follow_mouse"] ~= "no" then follow_mouse="-follow_mouse "..config["follow_mouse"] .. " " end

codec=codecs:get(config.codec)

if config["size"]=="no video" or codec.video==false
then
	--str="ffmpeg -nostats -filter_complex ebur128  -thread_queue_size 1024 " .. audio .. audio_filter .. codec.cmdline .. config.output_path .. codec.extn
	str="ffmpeg -filter_complex ebur128 -thread_queue_size 1024 " .. audio .. audio_filter .. codec.cmdline .. config.output_path .. codec.extn
	gui=AudioRecordDialog(config)
else
	str="ffmpeg -nostats -s " .. config["size"] .. " -r " .. config["fps"] .. " ".. show_pointer.. show_region .. follow_mouse .. " -f x11grab -thread_queue_size 1024 " .. " -i " .. Xdisplay .. " ".. audio .. audio_filter .. codec.cmdline .. config.output_path .. codec.extn


dialog=NewDialog(config)
if dialog.term ~= nil
then
dialog.term:clear()
end

gui=dialog:log("Close This Window To End Recording", 800, 400)
cmdS=stream.STREAM("cmd:" .. str, "rw +stderr noshell")
end

gui:add("LAUNCH: "..str)

cmdS=stream.STREAM("cmd:" .. str, "rw +stderr noshell")
poll=stream.POLL_IO()
poll:add(cmdS)
poll:add(gui.S)

while true
do
	S=poll:select(50)
	if process.collect ~= nil
	then
	process.collect()
	else
	process.childExited()
	end

	if S == cmdS 
	then
		str=cmdS:readln()

		if str==nil 
		then
			print("ERROR: ffmepg closed!")
			break
		else
			str=strutil.trim(str)
			gui:add(str)
		end
	elseif gui.S ~= nil and S == gui.S
	then
		str=gui.S:readln()
		io.stderr:write("GUI: "..str)
		-- anything from the logging window means the window has been closed
		break
	end
end

process.kill(tonumber(cmdS:getvalue("PeerPID")))
cmdS:close()

if dialog.term ~= nil
then
dialog.term:reset()
dialog.term:clear()
end

end


function PrintHelp()
print("screencast.lua version 1.0")
os.exit()
end


function ParseCommandLine(config)
local i,item

for i,item in ipairs(arg)
do
if item == "-?" or item == "--help" or item == "-help"
then 
	PrintHelp() 
elseif item == "-ui"
then
 config.driver=arg[i+1]
 arg[i+1]=""
elseif item == "-size"
then
 config.size=arg[i+1]
 arg[i+1]=""
elseif item == "-fps"
then
 config.fps=arg[i+1]
 arg[i+1]=""
elseif item == "-codec"
then
 config.codec=arg[i+1]
 arg[i+1]=""
elseif item == "-o"
then
 config.output_path=arg[i+1]
 arg[i+1]=""
end
end

return config
end


function InitConfig()
local config={}

config.output_path=sys.hostname() .. "-" .. time.format("%Y-%M-%YT%H-%M-%S")
config.follow_mouse="no"
config.fps=30
config.size=""
config.codec="mp4 (h264/aac)"

return config
end


config=InitConfig()
codecs=CodecsInit()
ParseCommandLine(config)
devices=GetSoundDevices()
dialogs=NewDialog(config)

config=SetupDialog(config, devices)


if config ~= nil
then 
if config.countdown ~= nil and tonumber(config.countdown) > 0 then DoCountdown(config.countdown) end
DoRecord(config)
end

print("END!")
