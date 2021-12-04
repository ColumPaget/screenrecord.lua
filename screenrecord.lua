require("stream")
require("strutil")
require("process")
require("filesys")
require("terminal")
require("time")
require("sys")



function tobool(str)

str=string.lower(strutil.trim(str))

if strutil.strlen(str) < 1 then return false end

if string.sub(str,1,1) =='y' then return true end
if string.sub(str,1,1) =='n' then return false end
if str=="true" then return true end
if str=="false" then return false end
if tonumber(str) > 0 then return true end

return false
end


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

codecs.get=function(self, name)
return self.items[name]
end

codecs.list=function(self)
local key, item, i, name
local str=""
local sort_table={}

for key,item in pairs(self.items)
do
	table.insert(sort_table, key)
end

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
if video["flv"] == true and audio["nellymoser"]==true then codecs:add("flv (flash player 7+ flv/nellymoser)", " -vcodec flv -acodec nellymoser -ar 44100 ", ".flv") end
if video["flv"] == true and audio["aac"]==true then codecs:add("flv (flash player 9+ flv/aac)", " -vcodec flv -acodec aac ", ".flv") end
if video["h263"] == true and audio["libmp3lame"]==true then codecs:add("f4v (flash player 9+ h263/mp3)", " -vcodec h263 -acodec libmp3lame ", ".f4v") end
if video["h263"] == true and audio["aac"]==true then codecs:add("f4v (flash player 9+ h263/aac)", " -vcodec h263 -acodec aac ", ".f4v") end
if video["h264"] == true and audio["aac"]==true then codecs:add("f4v (flash player 9+ h264/aac)", " -vcodec h264 -acodec aac ", ".f4v") end
if video["h264"] == true and audio["libmp3lame"]==true then codecs:add("f4v (flash player 9+ h264/mp3)", " -vcodec h264 -acodec libmp3lame ", ".f4v") end
if video["theora"]==true and audio["vorbis"]==true then codecs:add("ogv (theora/vorbis)", " -vcodec libtheora -qscale:v 10 -acodec libvorbis -qscale:a 10 ", ".ogv") end
if video["theora"]==true and audio["opus"]==true then codecs:add("ogv (theora/opus)", " -vcodec libtheora -qscale:v 10 -acodec libopus ", ".ogv") end
if video["theora"]==true and audio["flac"]==true then codecs:add("ogv (theora/flac)", " -vcodec libtheora -qscale:v 10 -acodec flac ", ".ogv") end
if video["h264"] == true and audio["aac"] == true then codecs:add("mp4 (h264/aac)", " -vcodec libx264 -preset ultrafast -acodec aac ", ".mp4") end
if video["h264"] == true and audio["libmp3lame"] == true then codecs:add("mp4 (h264/mp3)", " -vcodec libx264 -preset ultrafast -acodec libmp3lame ", ".mp4") end
if video["h264"] == true and audio["opus"] == true then codecs:add("mp4 (h264/opus)", " -vcodec libx264 -preset ultrafast -acodec libopus ", ".mp4") end
if video["h264"] == true and audio["vorbis"] == true then codecs:add("mp4 (h264/vorbis)", " -vcodec libx264 -preset ultrafast -acodec libvorbis ", ".mp4") end
if video["h264"] == true and audio["flac"] == true then codecs:add("mp4 (h264/flac)", " -vcodec libx264 -preset ultrafast -acodec flac ", ".mp4") end
if video["mpeg4"] == true and audio["aac"] == true then codecs:add("mp4 (mpeg4/aac)", " -vcodec mpeg4 -acodec aac ", ".mp4") end
if video["mpeg4"] == true and audio["libmp3lame"] == true then codecs:add("mp4 (mpeg4/mp3)", " -vcodec mpeg4 -acodec libmp3lame ", ".mp4") end
if video["mpeg4"] == true and audio["opus"] == true then codecs:add("mp4 (mpeg4/opus)", " -vcodec mpeg4 -acodec libopus ", ".mp4") end
if video["mpeg4"] == true and audio["vorbis"] == true then codecs:add("mp4 (mpeg4/vorbis)", " -vcodec mpeg4 -acodec libvorbis ", ".mp4") end
if video["mpeg4"] == true and audio["flac"] == true then codecs:add("mp4 (mpeg4/flac)", " -vcodec mpeg4 -acodec flac ", ".mp4") end
if video["vp8"] == true and audio["vorbis"] == true then codecs:add("webm (vp8/vorbis)", " -vcodec libvpx -acodec libvorbis ", ".webm") end
if video["vp9"] == true and audio["vorbis"] == true then codecs:add("webm (vp9/vorbis)", " -vcodec libvpx-vp9 -acodec libvorbis ", ".webm") end
if video["vp9"] == true and audio["opus"] == true then codecs:add("webm (vp9/opus)", " -vcodec libvpx-vp9 -acodec libopus ", ".webm") end
if audio["libmp3lame"] == true then codecs:add("audio:mp3", " -acodec libmp3lame ", ".mp3", false) end
if audio["opus"] == true then codecs:add("audio:opus", " -acodec libopus ", ".opus", false) end
if audio["vorbis"] == true then codecs:add("audio:ogg vorbis", " -acodec libvorbis ", ".ogg", false) end
if audio["flac"] == true then codecs:add("audio:flac", " -acodec flac ", ".flac", false) end



return codecs
end




function FormItemAdd(form, item_type, item_name, item_cmd_args, item_description)
local form_item={}

form_item.type=item_type
form_item.name=item_name
form_item.cmd_args=item_cmd_args
if item_description==nil
then
form_item.description=""
else
form_item.description=item_description
end

table.insert(form.config, #form.config+1, form_item)

--return newly created item so we can add other fields to it other than the default
return form_item
end


function FormParseOutput(form, result_str)
local results, form_item, val
local config={}

if strutil.strlen(result_str) == 0 then return nil end

results=strutil.TOKENIZER(result_str, "|")

for i,form_item in ipairs(form.config)
do
val=results:next()
if form_item.type=="boolean" 
then 
	config[form_item.name]=tobool(val)
else
	config[form_item.name]=val
end
end

return config
end


function FormFormatChoices(choices, selected)
local toks, item, combo_values
local unselected=""
local has_selection=false

if strutil.strlen(selected) > 0 then has_selection=true end

toks=strutil.TOKENIZER(choices, "|")
item=toks:next()

while item ~= nil
do
  if has_selection == false or selected ~= item 
  then 
	if strutil.strlen(unselected) > 0 then unselected=unselected .. "|" .. item 
	else unselected=item
	end
  end
  item=toks:next()
end

if has_selection == true then combo_values=selected.."|"..unselected
else combo_values=unselected
end

return combo_values
end



function QarmaFormAddBoolean(form, name)
form:add("boolean", name, "--add-checkbox='"..name.."'")
end


function QarmaFormAddChoice(form, name, choices, description, selected)
local combo_values
combo_values=FormFormatChoices(choices, selected)
form:add("choice", name, "--add-combo='"..name.."' --combo-values='".. combo_values .."'")
end

function QarmaFormAddEntry(form, name)
local str

str="--add-entry='"..name.."'"
form:add("entry", name, str)
end


function QarmaFormRun(form)
local str, S

str="qarma --forms --title='" .. form.title .."' "
for i,config_item in ipairs(form.config)
do
	str=str..config_item.cmd_args.. " "
end

S=stream.STREAM("cmd:"..str, "")
str=strutil.trim(S:readdoc())
S:close()

return FormParseOutput(form, str)
end


function QarmaYesNoDialog(text, flags)
local S, str, pid

str="cmd:qarma --question --text='"..text.."'"
S=stream.STREAM(str)
pid=S:getvalue("PeerPID")
str=S:readdoc()
S:close()

str=process.waitStatus(tonumber(pid));

if str=="exit:0" then return "yes" end
return "no"
end


function QarmaInfoDialog(text, width, height)
local S, str

str="cmd:qarma --info --text='"..text.."'"
if width > 0 then str=str.." --width "..tostring(width) end
if height > 0 then str=str.." --height "..tostring(height) end
S=stream.STREAM(str)
str=S:readdoc()
S:close()

end


function QarmaTextEntryDialog(text)
local S, str

str="cmd:qarma --entry"
S=stream.STREAM(str)
str=S:readdoc()
S:close()

return str
end


function QarmaFileSelectionDialog(text)
local S, str

str="cmd:qarma --file-selection --text='"..text.."'"
S=stream.STREAM(str)
str=S:readdoc()
S:close()

return str
end


function QarmaCalendarDialog(text)
local S, str

str="cmd:qarma --calendar --text='"..text.."'"
S=stream.STREAM(str)
str=S:readdoc()
S:close()

return str
end


function QarmaMenuDialog(text, options)
local S, str, toks, tok

str="cmd:qarma --list --hide-header --text='"..text.."' "

toks=strutil.TOKENIZER(options, "|")
tok=toks:next()
while tok ~= nil
do
str=str.. "'" .. tok .."' "
tok=toks:next()
end

S=stream.STREAM(str)
str=S:readdoc()
S:close()

return str
end



function QarmaLogDialog(form, text, width, height)
local S, str
local dialog={}

str="cmd:qarma --text-info --text='"..text.."'"
if width > 0 then str=str.." --width "..tostring(width) end
if height > 0 then str=str.." --height "..tostring(height) end

dialog.S=stream.STREAM(str)

dialog.add=function(dialog, text)
if text ~= nil then dialog.S:writeln(text.."\n") end
dialog.S:flush()
end


return dialog
end



function QarmaProgressDialog(text, max, close_on_full)
local str, S
local dialog={}

str="cmd:qarma --progress --text='".. text.."' "
if close_on_full == true then str=str.."--auto-close --auto-kill" end

dialog.max=max
dialog.S=stream.STREAM(str)

dialog.add=function(self, val, title)
local perc

	if val > 0 then perc=math.floor(val * 100 / max)
	else perc=val
	end

	if title ~= nil then self.S:writeln("# "..tostring(title).."\r\n") end
	self.S:writeln(string.format("%d\r\n", perc))
	self.S:flush()
end

return dialog
end




function QarmaFormObjectCreate(dialogs, title)
local form={}

form.title=title
form.config={}
form.add=FormItemAdd
form.addboolean=QarmaFormAddBoolean
form.addchoice=QarmaFormAddChoice
form.addentry=QarmaFormAddEntry
form.run=QarmaFormRun

return form
end


function QarmaObjectCreate()
local dialogs={}

dialogs.yesno=QarmaYesNoDialog
dialogs.info=QarmaInfoDialog
dialogs.entry=QarmaTextEntryDialog
dialogs.fileselect=QarmaFileSelectionDialog
dialogs.calendar=QarmaCalendarDialog
dialogs.menu=QarmaMenuDialog
dialogs.log=QarmaLogDialog
--dialogs.progress=QarmaProgressDialog
dialogs.form=QarmaFormObjectCreate

return dialogs
end


function ZenityFormAddBoolean(form, name)
form:add("boolean", name, "--add-combo='"..name.."' --combo-values='yes|no'")
end

function ZenityFormAddChoice(form, name, choices, description, selected)
local combo_values
combo_values=FormFormatChoices(choices, selected)

form:add("choice", name, "--add-combo='"..name.."' --combo-values='"..combo_values.."'")
end

function ZenityFormAddEntry(form, name)
form:add("entry", name, "--add-entry='"..name.."'")
end


function ZenityFormRun(form)
local str, S

str="zenity --forms --title='" .. form.title .. "' "
for i,config_item in ipairs(form.config)
do
	str=str..config_item.cmd_args.. " "
end

S=stream.STREAM("cmd:"..str, "")
str=strutil.trim(S:readdoc())
S:close()

return FormParseOutput(form, str)
end


function ZenityYesNoDialog(text, flags)
local S, str, pid

str="cmd:zenity --question --text='"..text.."'"
S=stream.STREAM(str)
pid=S:getvalue("PeerPID")
str=S:readdoc()
S:close()

str=process.waitStatus(tonumber(pid));

if str=="exit:0" then return "yes" end
return "no"
end


function ZenityInfoDialog(text)
local S, str

str="cmd:zenity --info --text='"..text.."'"
S=stream.STREAM(str)
str=S:readdoc()
S:close()

end


function ZenityTextEntryDialog(text)
local S, str

str="cmd:zenity --entry --text='"..text.."'"
S=stream.STREAM(str)
str=S:readdoc()
S:close()

return str
end


function ZenityFileSelectionDialog(text)
local S, str

str="cmd:zenity --file-selection --text='"..text.."'"
S=stream.STREAM(str)
str=S:readdoc()
S:close()

return str
end


function ZenityCalendarDialog(text)
local S, str

str="cmd:zenity --calendar --text='"..text.."'"
S=stream.STREAM(str)
str=S:readdoc()
S:close()

return str
end


function ZenityMenuDialog(text, options)
local S, str, toks, tok

str="cmd:zenity --list --hide-header --text='"..text.."' "

toks=strutil.TOKENIZER(options, "|")
tok=toks:next()
while tok ~= nil
do
str=str.. "'" .. tok .."' "
tok=toks:next()
end

S=stream.STREAM(str)
str=S:readdoc()
S:close()

return str
end


function ZenityProgressDialog(text, max, close_on_full)
local str, S
local dialog={}

str="cmd:zenity --progress --text='".. text.."' "
if close_on_full==true then str=str.." --auto-close --auto-kill" end

dialog.max=max
dialog.S=stream.STREAM(str)

dialog.add=function(self, val)
local perc

	if val > 0 then perc=math.floor(val * 100 / max)
	else perc=val
	end

	self.S:writeln(string.format("%d\r\n", perc))
	self.S:flush()
end

return dialog
end




function ZenityLogDialog(form, text)
local S, str
local dialog={}

str="cmd:zenity --text-info --auto-scroll --title='"..text.."'"
dialog.S=stream.STREAM(str)
dialog.add=function(self, text)
if text ~= nil then self.S:writeln(text.."\n") end
self.S:flush()
end


return dialog
end




function ZenityFormObjectCreate(dialogs, title)
local form={}

form.title=title
form.config={}
form.add=FormItemAdd
form.addboolean=ZenityFormAddBoolean
form.addchoice=ZenityFormAddChoice
form.addentry=ZenityFormAddEntry
form.run=ZenityFormRun

return form
end


function ZenityObjectCreate()
local dialogs={}

dialogs.yesno=ZenityYesNoDialog
dialogs.info=ZenityInfoDialog
dialogs.entry=ZenityTextEntryDialog
dialogs.fileselect=ZenityFileSelectionDialog
dialogs.calendar=ZenityCalendarDialog
dialogs.menu=ZenityMenuDialog
dialogs.log=ZenityLogDialog
--dialogs.progress=ZenityProgressDialog
dialogs.form=ZenityFormObjectCreate

return dialogs
end




function YadFormAddBoolean(form, name)
form:add("boolean", name, "--field='"..name..":CHK' ''")
end


function YadFormAddChoice(form, name, choices, description, selected)
local combo_values
combo_values=FormFormatChoices(choices, selected)

form:add("choice", name, "--field='"..name..":CB' '"..string.gsub(combo_values,'|', '!').."'")
end


function YadFormAddEntry(form, name)
form:add("entry", name, "--add-entry='"..name.."'")
end


function YadFormRun(form)
local str, S, i, config_item

str="yad --form --title='" .. form.title .. "' "
for i,config_item in ipairs(form.config)
do
	str=str..config_item.cmd_args.. " "
end

S=stream.STREAM("cmd:"..str, "")
str=strutil.trim(S:readdoc())
S:close()

return FormParseOutput(form, str)
end



function YadYesNoDialog(text, flags)
local S, str, pid

str="cmd:yad --question --text='"..text.."'"
S=stream.STREAM(str)
pid=S:getvalue("PeerPID")
str=S:readdoc()
S:close()

str=process.waitStatus(tonumber(pid));

if str=="exit:0" then return "yes" end
return "no"
end


function YadInfoDialog(text)
local S, str

str="cmd:yad --text='"..text.."'"
S=stream.STREAM(str)
str=S:readdoc()
S:close()

end


function YadTextEntryDialog(text)
local S, str

str="cmd:yad --entry --text='"..text.."'"
S=stream.STREAM(str)
str=S:readdoc()
S:close()

return str
end



function YadFileSelectionDialog(text)
local S, str

str="cmd:yad --file-selection --text='"..text.."'"
S=stream.STREAM(str)
str=S:readdoc()
S:close()

return str
end


function YadCalendarDialog(text)
local S, str

str="cmd:yad --calendar --text='"..text.."'"
S=stream.STREAM(str)
str=S:readdoc()
S:close()

return str
end



function YadLogDialogAddText(dialog, text)
if text ~= nil then dialog.S:writeln(text.."\n") end
dialog.S:flush()
end


function YadLogDialog(form, text)
local S, str
local dialog={}

str="cmd:yad --text-info "
if strutil.strlen(text) > 0 then str=str.." --text='"..text.."'" end
dialog.S=stream.STREAM(str)
dialog.add=YadLogDialogAddText

return dialog
end



function YadMenuDialog(text, options)
local S, str, toks, tok

str="cmd:yad --list --no-headers --column='c1' " 
toks=strutil.TOKENIZER(options, "|")
tok=toks:next()
while tok ~= nil
do
str=str.. "'" .. tok .."' "
tok=toks:next()
end

S=stream.STREAM(str)
str=S:readdoc()
S:close()

return str
end




function YadFormObjectCreate(dialogs, title)
local form={}

form.title=title
form.config={}
form.add=FormItemAdd
form.addboolean=YadFormAddBoolean
form.addchoice=YadFormAddChoice
form.addentry=YadFormAddEntry
form.run=YadFormRun

return form
end


function YadObjectCreate()
local dialogs={}

dialogs.yesno=YadYesNoDialog
dialogs.info=YadInfoDialog
dialogs.entry=YadTextEntryDialog
dialogs.fileselect=YadFileSelectionDialog
dialogs.calendar=YadCalendarDialog
dialogs.log=YadLogDialog
dialogs.menu=YadMenuDialog
--dialogs.progress=YadProgressDialog
dialogs.form=YadFormObjectCreate

return dialogs
end


function TextConsoleInfoDialog(text)

end


function TextConsoleTextEntryDialog(form, text)
local str

str=form.prompt(text..":")

return str
end



function TextConsoleFileSelectionDialog(text)
local str

return str
end


function TextConsoleCalendarDialog(text)
local str

return str
end



function TextConsoleLogDialogAddText(dialog, text)
dialog.term:puts(text.."\n")
end


function TextConsoleLogDialog(form, text)
local dialog={}

--there is no communication stream to a dialog application
--as this type of dialog is supported by native libUseful
--terminal functions
dialog.S=form.stdio

dialog.term=form.term
dialog.add=TextConsoleLogDialogAddText
dialog.term:bar("PRESS ANY KEY TO END RECORDING")

return dialog
end



function TextConsoleMenuDialog(form, text, options, description)
local S, str, toks, tok, menu

if description==nil then description="" end

form.term:clear()
form.term:move(2,2)
form.term:puts("Choose '"..text.."'  - " .. description)
menu=terminal.TERMMENU(form.term, 2, 4, form.term:width()-4, form.term:length() - 10)

toks=strutil.TOKENIZER(options, "|")
tok=toks:next()
while tok ~= nil
do
	menu:add(tok, tok)
	tok=toks:next()
end

str=menu:run()

return str
end



function TextConsoleYesNoDialog(form, text, description)
return TextConsoleMenuDialog(form, text, "yes|no", description)
end



function TextConsoleFormAddBoolean(form, name, description)
form:add("boolean", name, "", description)
end


function TextConsoleFormAddChoice(form, name, choices, description, selected)
local item
item=form:add("choice", name, "", description)
item.choices=choices
end


function TextConsoleFormAddEntry(form, name, description)
form:add("entry", name, "", description)
end


function TextConsoleFormRun(form)
local str, results, toks, tok

form.term:clear()
results=""

for i,form_item in ipairs(form.config)
do

	if form_item.type == "boolean"
	then
		str=TextConsoleYesNoDialog(form, form_item.name, form_item.description)
		results=results..str.."|"
	elseif form_item.type=="choice"
	then
		str=TextConsoleMenuDialog(form, form_item.name, form_item.choices, form_item.description)
		results=results..str.."|"
	elseif qtype=="entry"
	then
		str=TextConsoleTextEntryDialog(form, form_item.name, form_item.description)
		results=results..str.."|"
	end
end

form.term:reset()
return FormParseOutput(form, results)
end




function TextConsoleFormObjectCreate(dialogs, title)
local form={}

form.title=title
form.stdio=dialogs.stdio
form.term=dialogs.term
form.config={}
form.add=FormItemAdd
form.addboolean=TextConsoleFormAddBoolean
form.addchoice=TextConsoleFormAddChoice
form.addentry=TextConsoleFormAddEntry
form.run=TextConsoleFormRun

return form
end


function TextConsoleObjectCreate()
local dialogs={}

dialogs.stdio=stream.STREAM("-")

dialogs.term=terminal.TERM(dialogs.stdio)
dialogs.yesno=TextConsoleYesNoDialog
dialogs.info=TextConsoleInfoDialog
dialogs.entry=TextConsoleTextEntryDialog
dialogs.fileselect=TextConsoleFileSelectionDialog
dialogs.calendar=TextConsoleCalendarDialog
dialogs.log=TextConsoleLogDialog
dialogs.menu=TextConsoleMenuDialog
--dialogs.progress=TextConsoleProgressDialog
dialogs.form=TextConsoleFormObjectCreate

return dialogs
end



function DialogSelectDriver()

if strutil.strlen(filesys.find("zenity", process.getenv("PATH"))) > 0 then return "zenity" end
if strutil.strlen(filesys.find("qarma", process.getenv("PATH"))) > 0 then return "qarma" end
if strutil.strlen(filesys.find("yad", process.getenv("PATH"))) > 0 then return "yad" end

return "native"
end


function NewDialog(config)
local dialog={}
local driver

driver=config.driver
dialog.config=""

if strutil.strlen(driver) == 0 then driver=DialogSelectDriver() end

if driver == "qarma"
then
	dialog=QarmaObjectCreate()
elseif driver == "zenity"
then
	dialog=ZenityObjectCreate()
elseif driver == "yad"
then
	dialog=YadObjectCreate()
else
	dialog=TextConsoleObjectCreate(dialog)
end

return dialog
end



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
return devices
end


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
local dialog={}

dialog=NewDialog(config)
form=dialog:form("setup screen recording")

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

dialog=QarmaProgressDialog("recording in:", count, true)
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
gui=dialog:log("Close This Window To End Recording", 800, 400)
cmdS=stream.STREAM("cmd:" .. str, "rw +stderr noshell")
end

print("LAUNCH: "..str)

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
		-- anything from the logging window means the window has been closed
		break
	end
end

process.kill(tonumber(cmdS:getvalue("PeerPID")))
cmdS:close()

if gui.term ~= nil
then
log.term:clear()
log.term:reset()
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
elseif item == "-dialog"
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
config=SetupDialog(config, devices)


if config ~= nil
then 
if config.countdown ~= nil and tonumber(config.countdown) > 0 then DoCountdown(config.countdown) end
DoRecord(config)
end


