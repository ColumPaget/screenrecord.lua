

all:
	cat includes.lua common.lua config.lua dialog-types.lua codecs.lua sound.lua log.lua main.lua > screenrecord.lua
	chmod a+x screenrecord.lua

install:
	cp screenrecord.lua /usr/local/bin -f
