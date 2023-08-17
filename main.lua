

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
function DoRecordProcessFeedback(S, cmdS, gui, log)
local str

	if S == cmdS 
	then
		str=cmdS:readln()

		if str==nil 
		then
			return(false)
		else
			str=strutil.trim(str)
			-- this output can be used to get an 'audio level' for a vu meter
			if string.sub(str, 1, 15)=="[Parsed_ebur128" then gui:add_level(str)
			else log:add(str)
			end
		end
	elseif gui.S ~= nil and S == gui.S
	then
		str=gui.S:readln()
		-- anything from the gui window means the window has been closed
		return(false)
	end

return(true)
end



function DoRecordLoop(poll, cmdS, gui, log)
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
		if DoRecordProcessFeedback(S, cmdS, gui, log) == false then break end
	else
		gui:add_level("")	
	end

	--did we get any signals that tell us to stop?
	if process.sigcheck(process.SIGINT) then break end
	if process.sigcheck(process.SIGTERM) then break end
end

gui:close()
log:display()

end


function CommandLineRecordingGui()
gui={}

gui.add=function(self, text)
print(text)
end

gui.close=function(self)
end

return gui
end


function DoRecord(config)
local cmdS, S, poll, dialog, str
local gui, log


--watch for signals that tell us to stop recording
process.sigwatch(process.SIGINT)
process.sigwatch(process.SIGTERM)

--[[
if config.no_dialog == false then gui=RecordingActiveDialog(config)
else gui=CommandLineRecordingGui()
end
]]--

filesys.mkdirPath(config.output_path)
str=FFMPEGBuildCommandLine(config)
cmdS=stream.STREAM("cmd:" .. str, "rw +stderr noshell newpgroup")

if cmdS ~= nil
then
-- only create gui after launching ffmpeg, as FFMPEGBuildCommandLine changes some things in config
-- and also why launch gui if cmdS is null?
gui=RecordingActiveDialog(config)

poll=stream.POLL_IO()
poll:add(gui.S)
poll:add(cmdS)

log=ProcessLogInit()
time.usleep(30)

DoRecordLoop(poll, cmdS, gui, log)

process.kill(0 - tonumber(cmdS:getvalue("PeerPID")))

if gui.term ~= nil
then
gui.term:reset()
gui.term:clear()
end

cmdS:close()
else
io.stderr:write("ERROR: Failed to launch ffmpeg")
end

end



codecs=CodecsInit()
sound=SoundInit()
config=InitConfig(codecs:get_default())

dialogs=NewDialog(config.driver)

if codecs==nil
then
dialogs.info("Can't initialize ffmpeg. Is it installed?", "FFMPEG ERROR")
os.exit(1)
end

if config.no_dialog == false then config=RecordDialogSetup(config) end


if config ~= nil
then 
if strutil.strlen(config.countdown) > 0 and tonumber(config.countdown) > 0 then DoCountdown(config.countdown) end
DoRecord(config)
end

