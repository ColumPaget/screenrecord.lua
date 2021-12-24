SYNOPSIS
========

screenrecord.lua is a lua script that launches an ffmpeg process for screen-recording on xorg/X11. It can also record audio, with or without screen recording, using OSS, ALSA or PulseAudio (ALSA is recommended). For GUI it utilizes either zenity, yad, qarma or a simple text-based interface. It requires libuseful (https://github.com/ColumPaget/libUseful) and libUseful-lua (https://github.com/ColumPaget/libUseful-lua) to be installed.

screenrecord.lua autodetects the ui-types that are available, and to some extent OSS, ALSA and PulseAudio sources that are available (though some of these may not work, as for many devices it's not easy to detect if the input is mono or stereo, and so both are offered but one will fail).



USAGE
=====

  lua screencast.lua [options]

OPTIONS
=======

```Â
  -ui <type>          specify ui type to use. Values are qarma, zenity, yad or text
  -size <x.y>         specify recording window size
  -fps <value>        frames per second to record at
  -outdir <path>      path to directory to store recordings in
  -o <path>           full path to recording file to create
  -?                  help text
  -help               help text
  --help              help text
```Â
