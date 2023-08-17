--setup command line for ffmpeg process



function FFMPEGBuildAudioConfig(config)
local dev, str
local audio=""
local audio_filter=""

	dev=sound:get(config.audio)
	if dev ~= nil 
	then

	if dev.type == "alsa"
	then
		if tonumber(dev.num) > -1
		then
		audio="-f " .. dev.type .. " -thread_queue_size 1024 -ac ".. dev.channels .. " -i hw:" .. dev.num.." "
		else
		audio="-f " .. dev.type .. " -thread_queue_size 1024 -ac ".. dev.channels .. " -i " .. dev.name.." "
		end
		
	elseif dev.type == "oss"
	then
		audio="-f " .. dev.type .. " -thread_queue_size 1024 -ac ".. dev.channels .. " -i " .. dev.name.." "
	elseif dev.type == "pulseaudio"
	then
		audio="-f pulse -thread_queue_size 1024 -ac ".. dev.channels .." -i default "
	end


	audio_filter=audio_filter .. " -filter_complex ebur128"
	if config["noise reduction"] == true then audio_filter=audio_filter .. ",highpass=f=200,lowpass=f=3000" end
	audio_filter=audio_filter .. " "
	end
	
	return audio, audio_filter
end


function FFMPEGBuildCommandLine(config)

local codec, str, Xdisplay
local show_region=""
local show_pointer=""
local follow_mouse=""
local audio=""
local audio_filter=""

if config["show_capture_region"] == true then show_region="-show_region 1" end
if config["hide_pointer"] == true then show_pointer="-draw_mouse 0" end
if config["follow_mouse"] == "edge" then follow_mouse="-follow_mouse 20"
elseif config["follow_mouse"] == "centered" then follow_mouse="-follow_mouse centered" 
end


if config.audio ~= "none"
then 
audio,audio_filter=FFMPEGBuildAudioConfig(config) 
end

codec=codecs:get_args(config.codec)

config.output_path = config.output_path .. codec.extn

if config["size"]=="no video" or codec.video==false
then
	--Audio only
	str="ffmpeg -nostats " .. audio .. audio_filter .. codec.cmdline .. config.output_path
else
	--Audio and Video (Default)

        Xdisplay=process.getenv("DISPLAY")

	str="ffmpeg -nostats  -f x11grab "  
	if strutil.strlen(config["size"]) > 0 then str=str .. "-s " .. config["size"] .. " " end
	str=str .. "-r " .. config["fps"] .. " "
	str=str .. show_region  .. " "
	str=str .. follow_mouse .. " "
	str=str .. show_pointer .. " "
	str=str .. " -i " .. Xdisplay .. " " --order of arguments matters, this must be at end of 'screen' options
	str=str .. audio .. audio_filter .. codec.cmdline .. config.output_path
end

io.stderr:write(str.."\n")

return str
end
