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


