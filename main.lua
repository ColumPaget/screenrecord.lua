





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



function AudioRecordDialog(record_config)
local dialog={}
local str, title

str="recording start: "..time.format("%H:%M:%S") .."   codec: "..record_config.codec .."\n"
str=str.."filename: " .. filesys.basename(record_config.output_path) ..  "\n"
str=str.."audio from: "..record_config.audio.."\n"
str=str.."video size: "..record_config.size

if dialogs.driver=="text"
then
				title="Press any key to end recording"
else
				title="Close this window to end recording"
end

dialog=dialogs:progress(title, str, 600, 200)
dialog.start_time=time.secs()
dialog.output_path=record_config.output_path
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

str="start: "..time.formatsecs("%H:%M:%S", self.start_time) 
str=str.."    duration: ".. time.formatsecs("%H:%M:%S", time.secs() - self.start_time)
str=str.."    filesize: " .. strutil.toMetric(filesys.size(self.output_path)) .. "b \n"
 
self:add_level(100 + dB, str)

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
		if tonumber(devnum) > -1
		then
		audio="-f " .. audio_type .. " -thread_queue_size 1024 -ac ".. channels .. " -i hw:" .. devnum.." "
		else
		audio="-f " .. audio_type .. " -thread_queue_size 1024 -ac ".. channels .. " -i " .. devname.." "
		end
		
	elseif audio_type == "oss"
	then
		audio="-f " .. audio_type .. " -thread_queue_size 1024 -ac ".. channels .. " -i " .. devname.." "
	elseif audio_type == "pulseaudio"
	then
		audio="-f pulse -thread_queue_size 1024 -ac ".. channels .." -i default "
	end


	audio_filter=audio_filter .. " -filter_complex ebur128"
	if config["noise reduction"] == true then audio_filter=audio_filter .. ",highpass=f=200,lowpass=f=3000" end
	audio_filter=audio_filter .. " "
	return audio, audio_filter
end


-- handle any output/messages that come out of the recording command
-- or the associated gui
function DoRecordProcessFeedback(poll, cmdS, gui, log)
local S, str

while true
do
	S=poll:select(50)
	if process.collect ~= nil
	then
	process.collect()
	else
	process.childExited()
	end

	if S ~= nil
	then
	if S == cmdS 
	then
		str=cmdS:readln()

		if str==nil 
		then
			gui:close()
			log:display()
			break
		else
			str=strutil.trim(str)
			-- this output can be used to get an 'audio level' for a vu meter
			if string.sub(str, 1, 15)=="[Parsed_ebur128" then gui:add(str)
			else log:add(str)
			end
		end
	elseif gui.S ~= nil and S == gui.S
	then
		str=gui.S:readln()
		-- anything from the gui window means the window has been closed
		break
	end
	end
end

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
if config.audio ~= "none"
then 
audio,audio_filter=BuildAudioConfig(config) 
end

if config["show capture region"] == true then show_region="-show_region 1 " end
--if config["show pointer"] == false then show_pointer="-draw_mouse 0 " end

if config["follow_mouse"] == "edge" then follow_mouse="-follow_mouse 20 "
elseif config["follow_mouse"] == "centered" then follow_mouse="-follow_mouse centered " 
end


codec=codecs:get(config.codec)

config.output_path = config.output_path .. codec.extn
if config["size"]=="no video" or codec.video==false
then
	--Audio only
	str="ffmpeg -nostats " .. audio .. audio_filter .. codec.cmdline .. config.output_path
else
	--Audio and Video (Default)
	str="ffmpeg -nostats -s " .. config["size"] .. " -r " .. config["fps"] .. " ".. show_pointer.. show_region .. follow_mouse .. " -f x11grab " .. " -i " .. Xdisplay .. audio .. audio_filter .. codec.cmdline .. config.output_path
end

gui=AudioRecordDialog(config)
filesys.mkdirPath(config.output_path)
cmdS=stream.STREAM("cmd:" .. str, "rw +stderr noshell newpgroup")
poll=stream.POLL_IO()
poll:add(gui.S)
poll:add(cmdS)

log=ProcessLogInit()
time.usleep(30)

DoRecordProcessFeedback(poll, cmdS, gui, log)

process.kill(0 - tonumber(cmdS:getvalue("PeerPID")))
cmdS:close()

if gui.term ~= nil
then
gui.term:reset()
gui.term:clear()
end


end



config=InitConfig()

dialogs=NewDialog(config.driver)

codecs=CodecsInit()
if codecs==nil
then
dialogs.info("Can't initialize ffmpeg. Is it installed?", "FFMPEG ERROR")
os.exit(1)
end

devices=GetSoundDevices()

config=SetupDialog(config, devices)


if config ~= nil
then 
if strutil.strlen(config.countdown) > 0 and tonumber(config.countdown) > 0 then DoCountdown(config.countdown) end
DoRecord(config)
end

