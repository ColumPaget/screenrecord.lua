


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

S=stream.STREAM("cmd:"..str, "rw setsid")
str=strutil.trim(S:readdoc())
S:close()

return FormParseOutput(form, str)
end


function QarmaYesNoDialog(dialogs, text, flags)
local S, str, pid

str="cmd:qarma --question --text='"..text.."'"
S=stream.STREAM(str, "rw setsid")
pid=S:getvalue("PeerPID")
str=S:readdoc()
S:close()

str=process.waitStatus(tonumber(pid));

if str=="exit:0" then return "yes" end
return "no"
end


function QarmaInfoDialog(dialogs, text, width, height)
local S, str

str="cmd:qarma --info --text='"..text.."'"
if width ~= nil and width > 0 then str=str.." --width "..tostring(width) end
if height ~= nil and height > 0 then str=str.." --height "..tostring(height) end
S=stream.STREAM(str, "rw setsid")
str=S:readdoc()
S:close()

end


function QarmaTextEntryDialog(dialogs, text)
local S, str

str="cmd:qarma --entry"
S=stream.STREAM(str, "rw setsid")
str=S:readdoc()
S:close()

return str
end


function QarmaFileSelectionDialog(dialogs, text)
local S, str

str="cmd:qarma --file-selection --text='"..text.."'"
S=stream.STREAM(str, "rw setsid")
str=S:readdoc()
S:close()

return str
end


function QarmaCalendarDialog(dialogs, text)
local S, str

str="cmd:qarma --calendar --text='"..text.."'"
S=stream.STREAM(str, "rw setsid")
str=S:readdoc()
S:close()

return str
end


function QarmaMenuDialog(dialogs, text, options)
local S, str, toks, tok

str="cmd:qarma --list --hide-header --text='"..text.."' "

toks=strutil.TOKENIZER(options, "|")
tok=toks:next()
while tok ~= nil
do
str=str.. "'" .. tok .."' "
tok=toks:next()
end

S=stream.STREAM(str, "rw setsid")
str=S:readdoc()
S:close()

return str
end



function QarmaLogDialog(form, text, width, height)
local str
local dialog={}

str="cmd:qarma --text-info --title='"..text.."'"
if width ~= nil and width > 0 then str=str.." --width "..tostring(width) end
if height ~= nil and height > 0 then str=str.." --height "..tostring(height) end

dialog.S=stream.STREAM(str, "rw setsid")
dialog.close=dialogs.generic_close

dialog.add=function(dialog, text)
if text ~= nil then dialog.S:writeln(text.."\n") end
dialog.S:flush()
end

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


function ZenityFormRun(form)
local str, S

str="zenity --forms --title='" .. form.title .. "' "
for i,config_item in ipairs(form.config)
do
	str=str..config_item.cmd_args.. " "
end

S=stream.STREAM("cmd:"..str, "rw setsid")
str=strutil.trim(S:readdoc())
S:close()

return FormParseOutput(form, str)
end


function ZenityYesNoDialog(dialog, text, flags)
local S, str, pid

str="cmd:zenity --question --text='"..text.."'"
S=stream.STREAM(str, "rw setsid")
pid=S:getvalue("PeerPID")
str=S:readdoc()
S:close()

str=process.waitStatus(tonumber(pid));

if str=="exit:0" then return "yes" end
return "no"
end


function ZenityInfoDialog(dialog, text)
local S, str

str="cmd:zenity --info --text='"..text.."'"
S=stream.STREAM(str, "rw setsid")
if S ~= nil
then
str=S:readdoc()
S:close()
end

end


function ZenityTextEntryDialog(dialog, text)
local S, str

str="cmd:zenity --entry --text='"..text.."'"
S=stream.STREAM(str, "rw setsid")
str=S:readdoc()
S:close()

return str
end


function ZenityFileSelectionDialog(dialog, text)
local S, str

str="cmd:zenity --file-selection --text='"..text.."'"
S=stream.STREAM(str, "rw setsid")
str=S:readdoc()
S:close()

return str
end


function ZenityCalendarDialog(dialog, text)
local S, str

str="cmd:zenity --calendar --text='"..text.."'"
S=stream.STREAM(str, "rw setsid")
str=S:readdoc()
S:close()

return str
end


function ZenityMenuDialog(dialog, text, options)
local S, str, toks, tok

str="cmd:zenity --list --hide-header --text='"..text.."' "

toks=strutil.TOKENIZER(options, "|")
tok=toks:next()
while tok ~= nil
do
str=str.. "'" .. tok .."' "
tok=toks:next()
end

S=stream.STREAM(str, "rw setsid")
str=S:readdoc()
S:close()

return str
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




function ZenityLogDialog(form, text)
local S, str
local dialog={}

str="cmd:zenity --text-info --auto-scroll --title='"..text.."'"
if width ~= nil and width > 0 then str=str.." --width "..tostring(width) end
if height ~= nil and height > 0 then str=str.." --height "..tostring(height) end

dialog.S=stream.STREAM(str, "rw setsid")
dialog.close=dialogs.generic_close

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
form:add("entry", name, "--field='"..name..":EB'")
end


function YadFormRun(form)
local str, S, i, config_item

str="yad --form --title='" .. form.title .. "' "
for i,config_item in ipairs(form.config)
do
	str=str..config_item.cmd_args.. " "
end

S=stream.STREAM("cmd:"..str, "rw setsid")
str=strutil.trim(S:readdoc())
S:close()

return FormParseOutput(form, str)
end



function YadYesNoDialog(dialog, text, flags)
local S, str, pid

str="cmd:yad --question --text='"..text.."'"
S=stream.STREAM(str, "rw setsid")
pid=S:getvalue("PeerPID")
str=S:readdoc()
S:close()

str=process.waitStatus(tonumber(pid));

if str=="exit:0" then return "yes" end
return "no"
end


function YadInfoDialog(dialog, text)
local S, str

str="cmd:yad --text='"..text.."'"
S=stream.STREAM(str, "rw setsid")
str=S:readdoc()
S:close()

end


function YadTextEntryDialog(dialog, text)
local S, str

str="cmd:yad --entry --text='"..text.."'"
S=stream.STREAM(str, "rw setsid")
str=S:readdoc()
S:close()

return str
end



function YadFileSelectionDialog(dialog, text)
local S, str

str="cmd:yad --file-selection --text='"..text.."'"
S=stream.STREAM(str, "rw setsid")
str=S:readdoc()
S:close()

return str
end


function YadCalendarDialog(dialog, text)
local S, str

str="cmd:yad --calendar --text='"..text.."'"
S=stream.STREAM(str, "rw setsid")
str=S:readdoc()
S:close()

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




function YadLogDialog(form, text)
local S, str
local dialog={}

str="cmd:yad --text-info "
if strutil.strlen(text) > 0 then str=str.." --text='"..text.."'" end
dialog.S=stream.STREAM(str, "rw setsid")

dialog.add=function(dialog, text)
if text ~= nil then dialog.S:writeln(text.."\n") end
dialog.S:flush()
end

return dialog
end



function YadMenuDialog(dialog, text, options)
local S, str, toks, tok

str="cmd:yad --list --no-headers --column='c1' " 
toks=strutil.TOKENIZER(options, "|")
tok=toks:next()
while tok ~= nil
do
str=str.. "'" .. tok .."' "
tok=toks:next()
end

S=stream.STREAM(str, "rw setsid")
str=S:readdoc()
S:close()

return str
end




function YadFormObjectCreate(dialog, title)
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
dialogs.progress=YadProgressDialog
dialogs.form=YadFormObjectCreate

return dialogs
end


function TextConsoleInfoDialog(dialog, text)

end


function TextConsoleTextEntryDialog(form, text, description)
local str

form.term:clear()
form.term:move(2,2)
form.term:puts("Enter '"..text.."'  "..description)

form.term:move(2,4)
str=form.term:prompt(text..": ")

return str
end



function TextConsoleFileSelectionDialog(dialog, text)
local str

return str
end


function TextConsoleCalendarDialog(dialog, text)
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
dialog.term:clear()

dialog.add=TextConsoleLogDialogAddText
dialog.term:bar(text)

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



function TextConsoleProgressDialog(dialogs, text, close_on_full)
local str, S
local progress={}

dialogs.term:clear()
dialogs.term:move(2,2)
dialogs.term:puts(text)

progress.max=100
progress.term=dialogs.term
dialog.close=dialogs.generic_close
dialog.set_max=dialogs.generic_setmax

progress.add=function(self, val)
self.term:move(2,3)
self.term:puts(string.format("%d", self.max - val))
end

return progress
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
	elseif form_item.type=="entry"
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


-- these are generic functions that are added to dialogs when
-- they are created. 'setmax' is only added to progress dialogs
-- 'close' is added to all dialog types
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

