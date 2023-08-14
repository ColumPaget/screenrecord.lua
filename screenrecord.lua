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

function PrintHelp()
print("screencast.lua version 1.0")
print("usage:")
print("  lua screencast.lua [options]")
print("options:")
print("  -ui <type>          specify ui type to use. Values are qarma, zenity, yad or text")
print("  -size <x.y>         specify recording window size")
print("  -fps <value>        frames per second to record at")
print("  -outdir <path>      path to directory to store recordings in")
print("  -o <path>           full path to recording file to create")
print("  -?                  this help")
print("  -help               this help")
print("  --help              this help")

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
elseif item == "-outdir"
then
 config.destdir=arg[i+1]
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

config.follow_mouse="no"
config.fps=30
config.size=""
config.codec="mp4 (h264/aac)"

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

perc=math.floor(val * 100 / progress.max)

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
else
	dialog=TextConsoleObjectCreate(dialog)
end

dialog.driver=driver

-- these are generic functions that are added to dialogss when
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

