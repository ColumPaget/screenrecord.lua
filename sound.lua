
function AddSoundDevice(devices, systype, devnum, name, channels)
local device={}

device.type=systype
device.num=devnum
device.name=name
device.channels=channels

table.insert(devices, device)
return device
end


function AddALSASoundDevice(devices, devnum, name)
local S, chans, str
local in_capture=false

S=stream.STREAM("/proc/asound/card"..devnum.."/stream0", "r")
if S ~= nil
then
	str=S:readln()
	while str ~= nil
	do
	str=strutil.trim(str)
	if str=="Capture:"
	then
		in_capture=true
	elseif str == ""
	then
		in_capture=false
	elseif string.sub(str, 1, 10) == "Channels: "
	then
		chans=tonumber(string.sub(str, 11))
	end
	str=S:readln()
	end
	S:close()
end

if chans==1
then
		AddSoundDevice(devices, "alsa", devnum, name, 1)
else
		AddSoundDevice(devices, "alsa", devnum, name, 1)
		AddSoundDevice(devices, "alsa", devnum, name, 2)
end

end


function ALSALoadSoundCards(devices)
local S, str, pos, name, toks, tok, devnum

AddSoundDevice(devices, "alsa", -1, "default", 1)
AddSoundDevice(devices, "alsa", -1, "default", 2)
S=stream.STREAM("/proc/asound/cards", "r");
str=S:readln()
while str ~= nil
do
		pos=string.find(str, ':') 
		name=strutil.trim(string.sub(str, pos+1))
		toks=strutil.TOKENIZER(str, " ")
		tok=toks:next()
		while tok ~= nil
		do
		if strutil.strlen(tok) > 0
		then
			devnum=tonumber(tok)
			break
		end
		tok=toks:next()
		end

		AddALSASoundDevice(devices, devnum, name)

		str=S:readln() --the next line is more information that we don't need
		str=S:readln()
end
S:close()
end


function OSSLoadSoundCards(devices)
local Glob, S, str, pos, devnum

devnum=0
Glob=filesys.GLOB("/dev/dsp*")
str=Glob:next()
while str ~= nil
do
	devnum=devnum+1
	AddSoundDevice(devices, "oss", devnum, str, 1)
	AddSoundDevice(devices, "oss", devnum, str, 2)
	str=Glob:next()
end
end



function GetSoundDevices()
local devices={}

OSSLoadSoundCards(devices)
ALSALoadSoundCards(devices)
AddSoundDevice(devices, "pulseaudio", 0, "", 1)
AddSoundDevice(devices, "pulseaudio", 0, "", 2)
return devices
end
