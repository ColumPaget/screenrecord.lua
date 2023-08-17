function SoundInit()
local sound={}

sound.devices={}


sound.add=function(self, systype, devnum, name, channels)
local device={}

device.type=systype
device.num=devnum
device.name=name
device.channels=channels
device.id=device.type..":"..tostring(device.num)
if channels==2 then device.id = device.id ..":s"
else device.id = device.id ..":m"
end

table.insert(self.devices, device)
return device
end


sound.add_alsa=function(self, devnum, name)
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
		self:add("alsa", devnum, name, 1)
else
		self:add("alsa", devnum, name, 1)
		self:add("alsa", devnum, name, 2)
end

end


sound.load_alsa=function(self)
local S, str, pos, name, toks, tok, devnum

self:add_alsa(-1, "default", 1)
self:add_alsa(-1, "default", 2)
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

		self:add_alsa(devnum, name)

		str=S:readln() --the next line is more information that we don't need
		str=S:readln()
end
S:close()
end


sound.load_oss=function(self)
local Glob, S, str, pos, devnum

devnum=0
Glob=filesys.GLOB("/dev/dsp*")
str=Glob:next()
while str ~= nil
do
	devnum=devnum+1
	self:add("oss", devnum, str, 1)
	self:add("oss", devnum, str, 2)
	str=Glob:next()
end
end



sound.load=function(self)
local devices={}

self:load_oss()
self:load_alsa()
self:add("pulseaudio", 0, "", 1)
self:add("pulseaudio", 0, "", 2)
end


sound.get=function(self, name)
local toks, requested, found

toks=strutil.TOKENIZER(name, " ")
requested=toks:next()

for i,item in ipairs(self.devices)
do
	if requested==item.id then return item end
end

return nil
end

sound.get_formatted=function(self, name)
local dev

dev=self:get(name)
if dev == nil then return("") end
return(self:format(dev))
end


sound.format=function(self, dev)
local str

  str=dev.id .. " " .. dev.name
  if dev.channels==1
  then
    str=str..":mono"
  else
    str=str..":stereo"
  end

return str
end


sound.list=function(self)
local devices, i, dev
local str=""

str="none"
for i,dev in ipairs(self.devices)
do
  str=str.."|"..self:format(dev)
end

return str
end



sound:load()
return sound
end
