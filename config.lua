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

print("OUT: "..config.output_path)
return config
end

