

all:
	cat includes.lua common.lua config.lua dialog-types.lua codecs.lua sound.lua screen.lua log.lua countdown-dialog.lua record-setup.lua recording-dialog.lua ffmpeg.lua main.lua > screenrecord.lua
	chmod a+x screenrecord.lua

install:
	cp screenrecord.lua /usr/local/bin -f
