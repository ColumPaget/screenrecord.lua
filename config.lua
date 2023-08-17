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

