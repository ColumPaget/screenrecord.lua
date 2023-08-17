function CodecsInit()
local codecs={}
local video={} audio={}
local cmdS, str

codecs.items={}

codecs.add=function(self, name, cmdline, extn, has_video)
local codec={}

codec.name=name
codec.extn=extn
codec.cmdline=cmdline
self.items[name]=codec

-- has_video could be nil, or something else, so we only set it false
-- if false is actually passed
if has_video == false 
then 
codec.video=false
else
codec.video=true 
end

end


codecs.get_default=function(self)
local choice, i, toks

for i,choice in pairs({"ogv", "mp4:h264:aac", "mp4:aac", "mp4:ogg", "mp4:mp3"})
do
if self:get_title(choice) ~= nil then return choice end
end

end


codecs.get_title=function(self, name)
local key, value, toks, tag

toks=strutil.TOKENIZER(name, " ")
tag=toks:next()

for key,value in pairs(self.items)
do
toks=strutil.TOKENIZER(key, " ")
if tag == toks:next() then return(key) end
end

return(nil)
end



codecs.get_args=function(self, name)
local key, value, toks, tag

toks=strutil.TOKENIZER(name, " ")
tag=toks:next()

for key,value in pairs(self.items)
do
toks=strutil.TOKENIZER(key, " ")
if tag == toks:next() then return(value) end
end

return(nil)
end



codecs.list=function(self)
local key, item, i, name
local str=""
local sort_table={}

for key,item in pairs(self.items)
do
	table.insert(sort_table, key)
end

str=self:get_default()
table.sort(sort_table)
for i,name in ipairs(sort_table)
do
	if strutil.strlen(str) == 0 then str=name
	else str=str.."|"..name
	end
end

return str
end

cmdS=stream.STREAM("cmd:ffmpeg -encoders", "rw +stderr noshell")
if cmdS == nil then return(nil) end

str=cmdS:readln()
while str ~= nil
do
str=strutil.trim(str)
toks=strutil.TOKENIZER(str, " ")
toks:next()
name=toks:next()

if name=="flv" then video["flv"]=true
elseif name=="h261" then video["h261"]=true
elseif name=="h263" then video["h263"]=true
elseif name=="libx264" then video["h264"]=true
elseif name=="libx265" then video["h265"]=true
elseif name=="mpeg4" then video["mpeg4"]=true
elseif name=="libtheora" then video["theora"]=true
elseif name=="libvpx" then video["vp8"]=true
elseif name=="libvpx-vp9" then video["vp9"]=true
elseif name=="vc2" then video["vc2"]=true
elseif name=="aac" then audio["aac"]=true
elseif name=="ac3" then audio["ac3"]=true
elseif name=="libopus" then audio["opus"]=true
elseif name=="flac" then audio["flac"]=true
elseif name=="libvorbis" then audio["vorbis"]=true
elseif name=="libmp3lame" then audio["libmp3lame"]=true
elseif name=="nellymoser" then audio["nellymoser"]=true
end

str=cmdS:readln()
end
cmdS:close()

--only works at certain resolutions and I can't be bothered with that right now
-- if video["h263"] == true and audio["aac"]==true then codecs:add("3gp (h263/aac)", " -vcodec h263 -acodec aac ", ".3gp") end

if video["flv"] == true and audio["libmp3lame"]==true then codecs:add("flv (flash player 7+ flv/mp3)", " -vcodec flv -acodec libmp3lame -ar 44100 ", ".flv") end
if video["flv"] == true and audio["nellymoser"]==true then codecs:add("flv:nm (flash player 7+ flv/nellymoser)", " -vcodec flv -acodec nellymoser -ar 44100 ", ".flv") end
if video["flv"] == true and audio["aac"]==true then codecs:add("flv:aac (flash player 9+ flv/aac)", " -vcodec flv -acodec aac ", ".flv") end
if video["h263"] == true and audio["libmp3lame"]==true then codecs:add("f4v:h263:mp3 (flash player 9+ h263/mp3)", " -vcodec h263 -acodec libmp3lame ", ".f4v") end
if video["h264"] == true and audio["libmp3lame"]==true then codecs:add("f4v:h264:mp3 (flash player 9+ h264/mp3)", " -vcodec h264 -acodec libmp3lame ", ".f4v") end
if video["h263"] == true and audio["aac"]==true then codecs:add("f4v:h263:aac (flash player 9+ h263/aac)", " -vcodec h263 -acodec aac ", ".f4v") end
if video["h264"] == true and audio["aac"]==true then codecs:add("f4v:h264:aac (flash player 9+ h264/aac)", " -vcodec h264 -acodec aac ", ".f4v") end
if video["theora"]==true and audio["vorbis"]==true then codecs:add("ogv (theora/ogg vorbis)", " -vcodec libtheora -qscale:v 10 -acodec libvorbis -qscale:a 10 ", ".ogv") end
if video["theora"]==true and audio["opus"]==true then codecs:add("ogv:opus (theora/opus)", " -vcodec libtheora -qscale:v 10 -acodec libopus ", ".ogv") end
if video["theora"]==true and audio["flac"]==true then codecs:add("ogv:flac (theora/flac)", " -vcodec libtheora -qscale:v 10 -acodec flac ", ".ogv") end
if video["h264"] == true and audio["aac"] == true then codecs:add("mp4:h264:aac (h264/aac)", " -vcodec libx264 -preset ultrafast -acodec aac ", ".mp4") end
if video["h264"] == true and audio["libmp3lame"] == true then codecs:add("mp4:h264:mp3 (h264/mp3)", " -vcodec libx264 -preset ultrafast -acodec libmp3lame ", ".mp4") end
if video["h264"] == true and audio["opus"] == true then codecs:add("mp4:h264:opus (h264/opus)", " -vcodec libx264 -preset ultrafast -acodec libopus ", ".mp4") end
if video["h264"] == true and audio["vorbis"] == true then codecs:add("mp4:h264:ogg (h264/ogg vorbis)", " -vcodec libx264 -preset ultrafast -acodec libvorbis ", ".mp4") end
if video["h264"] == true and audio["flac"] == true then codecs:add("mp4:h264:flac (h264/flac)", " -vcodec libx264 -preset ultrafast -acodec flac ", ".mp4") end
if video["mpeg4"] == true and audio["aac"] == true then codecs:add("mp4:aac (mpeg4/aac)", " -vcodec mpeg4 -acodec aac ", ".mp4") end
if video["mpeg4"] == true and audio["libmp3lame"] == true then codecs:add("mp4:mp3 (mpeg4/mp3)", " -vcodec mpeg4 -acodec libmp3lame ", ".mp4") end
if video["mpeg4"] == true and audio["opus"] == true then codecs:add("mp4:opus (mpeg4/opus)", " -vcodec mpeg4 -acodec libopus ", ".mp4") end
if video["mpeg4"] == true and audio["vorbis"] == true then codecs:add("mp4:ogg (mpeg4/ogg vorbis)", " -vcodec mpeg4 -acodec libvorbis ", ".mp4") end
if video["mpeg4"] == true and audio["flac"] == true then codecs:add("mp4:flac (mpeg4/flac)", " -vcodec mpeg4 -acodec flac ", ".mp4") end
if video["vp8"] == true and audio["vorbis"] == true then codecs:add("webm:vp8:ogg (vp8/ogg vorbis)", " -vcodec libvpx -acodec libvorbis ", ".webm") end
if video["vp9"] == true and audio["vorbis"] == true then codecs:add("webm:vp9:ogg (vp9/ogg vorbis)", " -vcodec libvpx-vp9 -acodec libvorbis ", ".webm") end
if video["vp9"] == true and audio["opus"] == true then codecs:add("webm:vp9:opus (vp9/opus)", " -vcodec libvpx-vp9 -acodec libopus ", ".webm") end
if audio["libmp3lame"] == true then codecs:add("audio:mp3", " -acodec libmp3lame ", ".mp3", false) end
if audio["opus"] == true then codecs:add("audio:opus", " -acodec libopus ", ".opus", false) end
if audio["vorbis"] == true then codecs:add("audio:ogg", " -acodec libvorbis ", ".ogg", false) end
if audio["flac"] == true then codecs:add("audio:flac", " -acodec flac ", ".flac", false) end



return codecs
end



