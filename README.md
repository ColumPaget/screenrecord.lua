SYNOPSIS
========

screenrecord.lua is a lua script that launches an ffmpeg process for screen-recording on xorg/X11. It can also record audio, with or without screen recording, using OSS, ALSA or PulseAudio (ALSA is recommended). For GUI it utilizes either zenity, yad, qarma or a simple text-based interface. It requires libuseful (https://github.com/ColumPaget/libUseful) and libUseful-lua (https://github.com/ColumPaget/libUseful-lua) to be installed.

screenrecord.lua autodetects the ui-types that are available, and to some extent OSS, ALSA and PulseAudio sources that are available (though some of these may not work, as for many devices it's not easy to detect if the input is mono or stereo, and so both are offered but one will fail).


AUTHOR
======

screenrecord.lua is (C) 2021 Colum Paget. It is released under the GPLv3 so you may do anything with them that the GPL allows.
Email: colums.projects@gmail.com


INSTALL
=======

The screenrecord.lua code is broken up into a number of submodules, with a simple makefile that concats these together into 'screenrecord.lua'. The resulting 'screenrecord.lua' can then be run by lua. So the default install is:

```
make
make install
```

the file 'screenrecord.lua' is the actual 'program' to be run by lua and is installed in '/usr/local/bin' by default. You can manually copy it to someplace else if you want. it can either be run as:

```
lua screenrecord.lua
```

or you can use linux's binfmt system to automatically invoke lua when the program is run.


USAGE
=====

  lua screencast.lua [options]

OPTIONS
=======

```
  -ui <type>          specify ui type to use. Values are qarma, zenity, yad or text
  -size <x.y>         specify recording window size
  -fps <value>        frames per second to record at
  -outdir <path>      path to directory to store recordings in
  -o <path>           full path to recording file to create
  -?                  help text
  -help               help text
  --help              help text
```
