require("stream")
require("strutil")
require("process")
require("filesys")
require("terminal")
require("time")

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



function QarmaFormAddBoolean(form, name)
form:add("boolean", name, "--add-checkbox='"..name.."'")
end

function QarmaFormAddChoice(form, name, choices)
form:add("choice", name, "--add-combo='"..name.."' --combo-values='"..choices.."'")
end

function QarmaFormAddEntry(form, name)
form:add("entry", name, "--add-entry='"..name.."'")
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


function QarmaInfoDialog(text)
local S, str

str="cmd:qarma --info --text='"..text.."'"
S=stream.STREAM(str)
str=S:readdoc()
S:close()

end


function QarmaTextEntryDialog(text)
local S, str

str="cmd:qarma --entry --text='"..text.."'"
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


function QarmaLogDialogAddText(dialog, text)
if text ~= nil then dialog.S:writeln(text.."\n") end
dialog.S:flush()
end


function QarmaLogDialog(form, text)
local S, str
local dialog={}

str="cmd:yad --text-info --text='"..text.."'"
dialog.S=stream.STREAM(str)
dialog.add=QarmaLogDialogAddText

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

function ZenityFormAddChoice(form, name, choices)
form:add("choice", name, "--add-combo='"..name.."' --combo-values='"..choices.."'")
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

print("FORM: "..str)
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


function ZenityLogDialogAddText(dialog, text)
if text ~= nil then dialog.S:writeln(text.."\n") end
dialog.S:flush()
end


function ZenityLogDialog(form, text)
local S, str
local dialog={}

str="cmd:zenity --text-info --auto-scroll --title='"..text.."'"
dialog.S=stream.STREAM(str)
dialog.add=ZenityLogDialogAddText

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


function YadFormAddChoice(form, name, choices)
form:add("choice", name, "--field='"..name..":CB' '"..string.gsub(choices,'|', '!').."'")
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


function TextConsoleFormAddChoice(form, name, choices, description)
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


function NewDialog()
local driver
local dialog={}

dialog.config=""
driver=DialogSelectDriver()

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


function GetSoundDevices()
local S, str, pos
local devices={}

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
		AddSoundDevice(devices, "alsa", devnum, name, 1)
		AddSoundDevice(devices, "alsa", devnum, name, 2)

		str=S:readln() --the next line is more information that we don't need
		str=S:readln()
end
S:close()

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


function SetupDialog(devices)
local str, S, toks, tok, device, config
local dialog={}

dialog=NewDialog()
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
form:addchoice("fps", "1|2|5|10|15|25|30", "(video frames per second)")
form:addchoice("size", GetScreenResolution().."|1024x768|800x600|640x480", "(area of screen to capture)")
form:addboolean("show capture region", "(draw outline of capture region on screen)")
form:addboolean("noise reduction", "(if audio, apply noise filters)")
form:addchoice("follow mouse", "no|edge|centered", "(capture region moves with mouse)")
--form:addentry("countdown", "(seconds of gracetime before recording)")

config=form:run()

return config
end



function DoCountdown(count)
local i, str, S, perc

S=stream.STREAM("cmd:qarma --progress --text='recording in:' --auto-close --auto-kill")
for i=0,count,1
do
	if i > 0 
	then 
		perc=math.floor(i * 100 / count)
	else 
		perc=0
	end

	str=string.format("%d\r\n", perc)
	S:writeln(str)
	S:flush()
	time.sleep(1)
end

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
local cmdS, S, poll, dialog, log, str, Xdisplay


Xdisplay=process.getenv("DISPLAY") .. " "
if config.audio ~= "none" then audio,audio_filter=BuildAudioConfig(config) end

if config["show capture region"] == true then show_region="-show_region 1 " end
--if config["show pointer"] == false then show_pointer="-draw_mouse 0 " end
if config["follow mouse"] ~= "no" then follow_mouse="-follow_mouse "..config["follow mouse"] .. " " end

str="ffmpeg -nostats -s " .. config["size"] .. " -r " .. config["fps"] .. " ".. show_pointer.. show_region .. follow_mouse .. " -f x11grab -thread_queue_size 1024 " .. " -i " .. Xdisplay .. " ".. audio .. audio_filter .. " -vcodec libx264 -preset ultrafast -acodec aac screencast.mp4"

print("LAUNCH: "..str)
filesys.unlink("screencast.mp4")

dialog=NewDialog()
log=dialog:log("Close This Window To End Recording")
cmdS=stream.STREAM("cmd:" .. str, "rw +stderr noshell")

poll=stream.POLL_IO()
poll:add(cmdS)
poll:add(log.S)

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
			log:add(str)
		end
	elseif log.S ~= nil and S == log.S
	then
		-- anything from the logging window means the window has been closed
		break
	end
end

process.kill(tonumber(cmdS:getvalue("PeerPID")))
cmdS:close()
if log.term ~= nil then log.term:reset() end

end



devices=GetSoundDevices()
config=SetupDialog(devices)
--if config.countdown ~= nil and tonumber(config.countdown) > 0 then DoCountdown(config.countdown) end

DoRecord(config)


