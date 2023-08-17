require("stream")
require("strutil")
require("process")
require("filesys")
require("terminal")
require("time")
require("sys")


VERSION=2.0

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

function PrintHelp()
print("screenrecord.lua version "..VERSION)
print("usage:")
print("  lua screenrecord.lua [options]")
print("options:")
print("  -N                  no ui, just honor command-line arguments")
print("  -ui <type>          specify ui type to use. Values are qarma, zenity, yad or text")
print("  -s <x.y>            specify recording window size")
print("  -size <x.y>         specify recording window size")
print("  -fps <value>        frames per second to record at")
print("  -c <value>          seconds of countdown before recoding starts")
print("  -count <value>      seconds of countdown before recoding starts")
print("  -countdown <value>  seconds of countdown before recoding starts")
print("  -C                  list codecs supported by ffmpeg")
print("  -list-codecs        list codecs supported by ffmpeg")
print("  -L                  list audio inputs supported by ffmpeg")
print("  -list-audio         list audio inputs supported by ffmpeg")
print("  -codec <name>       name (e.g. 'mp4:h264:aac', 'ogv:flac') of codec to use")
print("  -a <name>           name (e.g. 'alsa:1:s', 'oss:0:m') of sound-input to use")
print("  -audio <name>       name (e.g. 'alsa:1:s', 'oss:0:m') of sound-input to use")
print("  -sound <name>       name (e.g. 'alsa:1:s', 'oss:0:m') of sound-input to use")
print("  -noise              enable audio noise reduction")
print("  -nr                 enable audio noise reduction")
print("  -region             show capture region")
print("  -follow <type>      'follow mouse', either 'centered' or 'edge'")
print("  -outdir <path>      path to directory to store recordings in")
print("  -o <path>           full path to recording file to create")
print("  -?                  this help")
print("  -help               this help")
print("  --help              this help")
print("  --help              this help")
print("  -version            print program version")
print("  --version           print program version")

os.exit()
end


function PrintVersion()
print("screenrecord.lua: version " .. VERSION)
os.exit()
end


function ListItemOutput(item)
local toks, tok, str

toks=strutil.TOKENIZER(item, " ")
str=toks:next()
str=strutil.padto(str, ' ', 20)
tok=toks:remaining()
if tok ~= nil then str=str .. tok end
print(str)
end


function ListCodecs()
local str, toks, tok

str=codecs:list()
toks=strutil.TOKENIZER(str, "|")
item=toks:next()
while item ~= nil
do
ListItemOutput(item)
item=toks:next()
end

os.exit()
end

function ListSoundDevs()
local str, toks, tok

str=sound:list()
toks=strutil.TOKENIZER(str, "|")
item=toks:next()
while item ~= nil
do
ListItemOutput(item)
item=toks:next()
end

os.exit()
end



function ParseCommandLine(config)
local i,item

for i,item in ipairs(arg)
do
if item == "-?" or item == "--help" or item == "-help"
then 
  PrintHelp() 
elseif item == "--version" or item == "-version"
then
  PrintVersion()
elseif item == "-ui"
then
 config.driver=arg[i+1]
 arg[i+1]=""
elseif item == "-s" or item == "-size"
then
 config.size=arg[i+1]
 arg[i+1]=""
elseif item == "-fps"
then
 config.fps=arg[i+1]
 arg[i+1]=""
elseif item == "-c" or item == "-count" or item == "-countdown"
then
 config.countdown=arg[i+1]
 arg[i+1]=""
elseif item == "-follow"
then
 config.follow_mouse=arg[i+1]
 arg[i+1]=""
elseif item == "-codec"
then
 config.codec=arg[i+1]
 arg[i+1]=""
elseif item == "-a" or item == "-audio" or item == "-sound"
then
 config.audio=arg[i+1]
 arg[i+1]=""
elseif item == "-C" or item == "-list-codecs"
then
 ListCodecs()
elseif item == "-L" or item == "-list-sound"
then
 ListSoundDevs()
elseif item == "-outdir"
then
 config.destdir=arg[i+1]
 arg[i+1]=""
elseif item == "-o"
then
 config.output_path=arg[i+1]
--boolean options
elseif item == "-N" or item == "-nodialog" then config.no_dialog=true; config.driver="cli"
elseif item == "-noise" or item == "-nr" then config.noise_reduction=true
elseif item == "-region" then config.show_capture_region=true
end
end

return config
end


function InitConfig()
local config={}

config.no_dialog=false
config.follow_mouse="no"
config.fps=30
config.size=""
config.codec="mp4 (h264/aac)"
config.audio="none"

ParseCommandLine(config)

if strutil.strlen(config.output_path) == 0
then
config.output_path=""
if strutil.strlen(config.destdir) > 0 then config.output_path=config.destdir.."/" end
config.output_path=config.output_path .. sys.hostname() .. "-" .. time.format("%Y-%M-%YT%H-%M-%S")
end

return config
end



function DialogsProcessCmd(cmd)
local S, pid, str, status

S=stream.STREAM(cmd)
pid=S:getvalue("PeerPID")
str=S:readdoc()
if str ~= nil then str=strutil.trim(str) end
S:close()


status=process.childStatus(pid)
while status == "running"
do
time.sleep(0)
status=process.childStatus(pid)
end

--detect pressing 'cancel' and return nil
if status ~= "exit:0" then return nil end

return str
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

function QarmaFormAddEntry(form, name, text)
local str

str="--add-entry='"..name.."'"
if strutil.strlen(text) > 0 then str=str.." '"..text.."'" end

form:add("entry", name, str)
end


function QarmaFormRun(form, width, height)
local str, S

str="qarma --forms --title='" .. form.title .."' "
if strutil.strlen(form.text) > 0 then str=str.. "--text='" .. form.text .. "' " end
if width ~= nil and width > 0 then str=str.." --width "..tostring(width) end
if height ~= nil and height > 0 then str=str.." --height "..tostring(height) end



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
str=DialogsProcessCmd(str)

if str == nil then return "no" end
return "yes"
end


function QarmaInfoDialog(text, title, width, height)
local str

str="cmd:qarma --info --text='"..text.."'"
if width ~= nil and width > 0 then str=str.." --width "..tostring(width) end
if height ~= nil and height > 0 then str=str.." --height "..tostring(height) end
if strutil.strlen(title) > 0 then str=str.." --title '"..title.."'" end

str=DialogsProcessCmd(str)
-- str will be nil if user pressed cancel
return str
end


function QarmaTextEntryDialog(text, title)
local str

str="cmd:qarma --entry"
if strutil.strlen(text) > 0 then str=str.." --text '"..text.."'" end
if strutil.strlen(title) > 0 then str=str.." --title '"..title.."'" end

str=DialogsProcessCmd(str)
-- str will be nil if user pressed cancel
return str
end


function QarmaFileSelectionDialog(text, title)
local str

str="cmd:qarma --file-selection --text='"..text.."'"
if strutil.strlen(title) > 0 then str=str.." --title '"..title.."'" end

str=DialogsProcessCmd(str)
-- str will be nil if user pressed cancel
return str

end


function QarmaCalendarDialog(text)
local str

str="cmd:qarma --calendar --text='"..text.."'"
str=DialogsProcessCmd(str)
-- str will be nil if user pressed cancel
return str

end


function QarmaMenuDialog(text, options, title, width, height)
local str, toks, tok, pid

str="cmd:qarma --list --hide-header --text='"..text.."' "
if width ~= nil and width > 0 then str=str.." --width "..tostring(width) end
if height ~= nil and height > 0 then str=str.." --height "..tostring(height) end


if title ~= nil then str=str.." --title='"..title.."' " end

toks=strutil.TOKENIZER(options, "|")
tok=toks:next()
while tok ~= nil
do
str=str.. "'" .. tok .."' "
tok=toks:next()
end

str=DialogsProcessCmd(str)
-- str will be nil if user pressed cancel
return str
end


function QarmaLogDialogAddText(dialog, text)
if text ~= nil then dialog.S:writeln(text.."\n") end
dialog.S:flush()
end


function QarmaLogDialog(form, text, width, height)
local S, str
local dialog={}

str="cmd:qarma --text-info --text='"..text.."'"
if width ~= nil and width > 0 then str=str.." --width "..tostring(width) end
if height ~= nil and height > 0 then str=str.." --height "..tostring(height) end

dialog.S=stream.STREAM(str)
dialog.add=QarmaLogDialogAddText

return dialog
end




function QarmaProgressDialog(dialogs, title, text, width, height)
local str
local dialog={}

str="cmd:qarma --progress --cancel-label='Done' "
if strutil.strlen(text) > 0 then str=str.."--text='" .. text .. "' " end
if strutil.strlen(title) > 0 then str=str.."--title='".. title .."' " end
if width ~= nil and width > 0 then str=str.." --width "..tostring(width) end
if height ~= nil and height > 0 then str=str.." --height "..tostring(height) end


dialog.S=stream.STREAM(str, "rw setsid")
dialog.max=100
dialog.close=dialogs.generic_close
dialog.set_max=dialogs.generic_setmax

dialog.add=function(self, val, title)
local perc

	if val > 0 then perc=math.floor(val * 100 / self.max)
	else perc=val
	end

	if title ~= nil then self.S:writeln("# "..tostring(title).."\r\n") end
	self.S:writeln(string.format("%d\r\n", perc))
	self.S:flush()
end

return dialog
end





function QarmaFormObjectCreate(dialogs, title, text)
local form={}

form.title=title
form.text=text
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
dialogs.progress=QarmaProgressDialog
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


function ZenityFormRun(form, width, height)
local str, S

str="zenity --forms --title='" .. form.title .. "' "
if strutil.strlen(form.text) > 0 then str=str.. "--text='" .. form.text .. "' " end
if width ~= nil and width > 0 then str=str.." --width "..tostring(width) end
if height ~= nil and height > 0 then str=str.." --height "..tostring(height) end



for i,config_item in ipairs(form.config)
do
	str=str..config_item.cmd_args.. " "
end

S=stream.STREAM("cmd:"..str, "")
str=strutil.trim(S:readdoc())
S:close()

return FormParseOutput(form, str)
end


function ZenityYesNoDialog(text, flags, title)
local str, pid

str="cmd:zenity --question --text='"..text.."'"
if strutil.strlen(title) > 0 then str=str.." --title '"..title.."'" end

str=DialogsProcessCmd(str)
-- str will be nil if user pressed cancel
if str==nil then return "no" end
return "yes"
end


function ZenityInfoDialog(text, title)
local S, str

str="cmd:zenity --info --text=\""..text.."\""
if strutil.strlen(title) > 0 then str=str.." --title \""..title.."\"" end

str=DialogsProcessCmd(str)
-- str will be nil if user pressed cancel
return str

end


function ZenityTextEntryDialog(text, title)
local str

str="cmd:zenity --entry --text='"..text.."'"
if strutil.strlen(title) > 0 then str=str.." --title '"..title.."'" end

str=DialogsProcessCmd(str)
-- str will be nil if user pressed cancel
return str
end


function ZenityFileSelectionDialog(text, title)
local str

str="cmd:zenity --file-selection --text='"..text.."'"
if strutil.strlen(title) > 0 then str=str.." --title '"..title.."'" end

str=DialogsProcessCmd(str)
-- str will be nil if user pressed cancel
return str
end


function ZenityCalendarDialog(text, title)
local str

str="cmd:zenity --calendar --text='"..text.."'"
if strutil.strlen(title) > 0 then str=str.." --title '"..title.."'" end

str=DialogsProcessCmd(str)
-- str will be nil if user pressed cancel
return str
end


function ZenityMenuDialog(text, options, title)
local str, toks, tok

str="cmd:zenity --list --hide-header --text='"..text.."' "
if strutil.strlen(title) > 0 then str=str.." --title '"..title.."'" end

toks=strutil.TOKENIZER(options, "|")
tok=toks:next()
while tok ~= nil
do
str=str.. "'" .. tok .."' "
tok=toks:next()
end


str=DialogsProcessCmd(str)
-- str will be nil if user pressed cancel
return str
end


function ZenityLogDialogAddText(dialog, text)
if text ~= nil then dialog.S:writeln(text.."\n") end
dialog.S:flush()
end


function ZenityLogDialog(form, text, title)
local S, str
local dialog={}

str="cmd:zenity --text-info --auto-scroll --title='"..text.."'"
if strutil.strlen(title) > 0 then str=str.." --title '"..title.."'" end
dialog.S=stream.STREAM(str)
dialog.add=ZenityLogDialogAddText

return dialog
end



function ZenityProgressDialog(dialog, title, text, width, height)
local str, S
local dialog={}

str="cmd:zenity --progress --title='" .. title .. "' "
if strutil.strlen(text) > 0 then str=str.."--text='".. text.."' " end
if width ~= nil and width > 0 then str=str.." --width "..tostring(width) end
if height ~= nil and height > 0 then str=str.." --height "..tostring(height) end

dialog.max=100
dialog.S=stream.STREAM(str, "rw setsid")
dialog.close=dialogs.generic_close
dialog.set_max=dialogs.generic_setmax


dialog.add=function(self, val, title)
local perc

	if val > 0 then perc=math.floor(val * 100 / self.max)
	else perc=val
	end

	if title ~= nil then self.S:writeln("# "..tostring(title).."\r\n") end
	self.S:writeln(string.format("%d\r\n", perc))
	self.S:flush()
end



return dialog
end




function ZenityFormObjectCreate(dialogs, title, text)
local form={}

form.title=title
form.text=text
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
dialogs.progress=ZenityProgressDialog
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


function YadFormRun(form, width, height)
local str, S, i, config_item

str="yad --form --title='" .. form.title .. "' "
if strutil.strlen(form.text) > 0 then str=str.. "--text='" .. form.text .. "' " end
if width ~= nil and width > 0 then str=str.." --width "..tostring(width) end
if height ~= nil and height > 0 then str=str.." --height "..tostring(height) end


for i,config_item in ipairs(form.config)
do
	str=str..config_item.cmd_args.. " "
end

S=stream.STREAM("cmd:"..str, "")
str=strutil.trim(S:readdoc())
S:close()

return FormParseOutput(form, str)
end



function YadYesNoDialog(text, flags, title)
local str, pid

str="cmd:yad --question --text='"..text.."'"
if strutil.strlen(title) > 0 then str=str.." --title '"..title.."'" end

str=DialogsProcessCmd(str)
-- str will be nil if user pressed cancel

if str == nil then return "no" end
return "yes"
end


function YadInfoDialog(text, title)
local str

str="cmd:yad --text='"..text.."'"
if strutil.strlen(title) > 0 then str=str.." --title '"..title.."'" end

str=DialogsProcessCmd(str)
-- str will be nil if user pressed cancel
return str
end


function YadTextEntryDialog(text, title)
local str

str="cmd:yad --entry --text='"..text.."'"
if strutil.strlen(title) > 0 then str=str.." --title '"..title.."'" end

str=DialogsProcessCmd(str)
-- str will be nil if user pressed cancel
return str
end



function YadFileSelectionDialog(text, title)
local str

str="cmd:yad --file-selection --text='"..text.."'"
if strutil.strlen(title) > 0 then str=str.." --title '"..title.."'" end

str=DialogsProcessCmd(str)
-- str will be nil if user pressed cancel
return str
end


function YadCalendarDialog(text, title)
local str

str="cmd:yad --calendar --text='"..text.."'"
if strutil.strlen(title) > 0 then str=str.." --title '"..title.."'" end

str=DialogsProcessCmd(str)
-- str will be nil if user pressed cancel
return str

end



function YadLogDialogAddText(dialog, text)
if text ~= nil then dialog.S:writeln(text.."\n") end
dialog.S:flush()
end


function YadLogDialog(form, text, title)
local S, str
local dialog={}

str="cmd:yad --text-info "
if strutil.strlen(text) > 0 then str=str.." --text='"..text.."'" end
if strutil.strlen(title) > 0 then str=str.." --title '"..title.."'" end
dialog.S=stream.STREAM(str)
dialog.add=YadLogDialogAddText

return dialog
end



function YadMenuDialog(text, options, title)
local str, toks, tok

str="cmd:yad --list --no-headers --column='c1' " 
if strutil.strlen(title) > 0 then str=str.." --title '"..title.."'" end
toks=strutil.TOKENIZER(options, "|")
tok=toks:next()
while tok ~= nil
do
str=str.. "'" .. tok .."' "
tok=toks:next()
end

str=DialogsProcessCmd(str)
-- str will be nil if user pressed cancel
return str
end



function YadProgressDialog(dialog, title, text, width, height)
local str, S
local dialog={}

str="cmd:yad --progress --title='" .. title .. "' "
if strutil.strlen(text) > 0 then str=str.."--text='".. text.."' " end
if width ~= nil and width > 0 then str=str.." --width "..tostring(width) end
if height ~= nil and height > 0 then str=str.." --height "..tostring(height) end

dialog.max=100
dialog.S=stream.STREAM(str, "rw setsid")
dialog.close=dialogs.generic_close
dialog.set_max=dialogs.generic_setmax

dialog.add=function(self, val, title)
local perc

	if val > 0 then perc=math.floor(val * 100 / self.max)
	else perc=val
	end

	if title ~= nil then self.S:writeln("# "..tostring(title).."\r\n") end
	self.S:writeln(string.format("%d\r\n", perc))
	self.S:flush()
end



return dialog
end




function YadFormObjectCreate(dialogs, title, text)
local form={}

form.title=title
form.text=text
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
dialogs.progress=YadProgressDialog
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




function TextConsoleProgressDialog(dialogs, title, text)
local str
local progress={}

dialogs.term:clear()
dialogs.term:move(0,0)
dialogs.term:puts("~B~w"..title.."~>~0")
dialogs.term:move(0,3)
if strutil.strlen(text) > 0 then dialogs.term:puts(text) end

progress.S=dialogs.term.S
progress.max=100
progress.term=dialogs.term
progress.set_max=dialogs.generic_setmax

-- as we are not talking to a remote window/process
-- so 'close' is an empty function
progress.close=function(self)
end


progress.add=function(self, val, text)
local perc, i

self.term:move(0,8)
if strutil.strlen(text) > 0 then self.term:puts(text.."~>") end

self.term:move(2,9)

perc=math.floor(val * 100 / self.max)

str=""
for i=0,perc,1 do str=str.."*" end
for i=perc,100,1 do str=str.." " end

--str=string.format("%d", math.floor(self.max - tonumber(val)))
self.term:puts("["..str.."]~>")
self.term:flush()
end

return progress
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
dialogs.progress=TextConsoleProgressDialog
dialogs.form=TextConsoleFormObjectCreate

return dialogs
end



function CLIInfoDialog(text)
io.stderr:write(text.."\n")
end

function CLIProgressDialog(dialogs, title, text)
local dialog={}

if strutil.strlen(text) > 0 then io.stderr:write(text.."\n") end

dialog.max=100


dialog.set_max=function(self, val)
self.max=val
end

--update progress bar to position 'val' with underlying text 'text'
dialog.add=function(self, val, text)
local perc, i, str

perc=math.floor(val * 100 / self.max)
str=string.format("%d%%  ", perc)
if strutil.strlen(text) > 0 then str=str .. strutil.trim(text) end
io.stderr:write("\r" .. str .. "  ")
end


--very generic 'close' function
dialog.close=function(self)
end


return dialog
end


function CLILogDialog(dialogs, text)
local dialog={}

dialog.add=function(self, text)
io.stderr:write(text.."\n")
end

dialog.close=function(self)
end

return dialog
end



function CLIObjectCreate()
local dialogs={}

dialogs.stdio=stream.STREAM("-")
dialogs.info=CLIInfoDialog
dialogs.log=CLILogDialog
dialogs.progress=CLIProgressDialog

--[[ not implemented for Command Line Interface
dialogs.yesno=TextConsoleYesNoDialog
dialogs.entry=TextConsoleTextEntryDialog
dialogs.fileselect=TextConsoleFileSelectionDialog
dialogs.calendar=TextConsoleCalendarDialog
dialogs.menu=TextConsoleMenuDialog
dialogs.form=TextConsoleFormObjectCreate
]]--

return dialogs
end




function DialogSelectDriver()

if strutil.strlen(filesys.find("zenity", process.getenv("PATH"))) > 0 then return "zenity" end
if strutil.strlen(filesys.find("qarma", process.getenv("PATH"))) > 0 then return "qarma" end
if strutil.strlen(filesys.find("yad", process.getenv("PATH"))) > 0 then return "yad" end

return "native"
end


function NewDialog(driver)
local dialog={}


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
elseif driver == "cli"
then
	dialog=CLIObjectCreate()
else
	dialog=TextConsoleObjectCreate(dialog)
end

dialog.driver=driver

-- these are generic functions that are added to dialogs when
-- they are created. 'setmax' is only added to progress dialogss
-- 'close' is added to all dialogs types
dialog.generic_close=function(self)
if self.S ~= nil
then
process.kill(tonumber(0-self.S:getvalue("PeerPID")))
self.S:close()
end
end

dialog.generic_setmax=function(self, max)
self.max=tonumber(max)
end


return dialog
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
-- query screen info, like dimensions etc


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



function ProcessLogInit()
local log={}

log.lines={}

log.add=function(self, str)
local i

for i=1,10,1
do
	if log.lines[i+1] ~= nil then log.lines[i]=log.lines[i+1] end
	log.lines[10]=str
end

end


log.display=function(self)
local i, gui
local str=""

gui=dialogs:log("Error Report: ffmpeg exited. last lines were...", 600, 400)
for i=1,10,1
do
	gui:add(log.lines[i])
end

end

return log
end
-- display a countdown before starting recording, if the use requested that

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


-- this dialog displays when recording is taking place

function RecordingActiveCommandLine(text)
local gui={}

io.stderr:write(text)


gui.add_level=function(self, level, text)
local str
str=strutil.trim(text)
io.stderr:write("\r"..str.." ")
end

gui.close=function(self)
end

return gui
end


function RecordingActiveDialog(record_config)
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


-- ADD LEVEL function converts dB to a percent value for progressbars
dialog.add_level=function(self, str)
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
 
self:add(100 + dB, str)

end

return(dialog)
end


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

