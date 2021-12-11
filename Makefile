

all:
	cat includes.lua common.lua dialog-types.lua codecs.lua sound.lua main.lua > screenrecord.lua
	chmod a+x screenrecord.lua
