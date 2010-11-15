#!/usr/bin/env bash
SPEED=1.3
DEST=$1-upload.mp4
if [ -f $DEST ]
then
    echo $DEST already exists, quitting
    exit
fi

# Record
TMP=/tmp
RAW=$1-raw.mkv
FAST_AUDIO=$TMP/fast-audio.wav
FAST_VIDEO=$TMP/fast-video.mp4
COMP_AUDIO=$TMP/comp-audio.mp4
COMP_VIDEO=$TMP/comp-video.mp4

# TODO can I replace libx264 with copy? 
# TODO Change 2992 to 1920 for left side right screen
# This is where you change what section of the screen is recorded. See -s and -i
ffmpeg -f alsa -ac 2 -i pulse -f x11grab -r 30 -s 848x464 -i :0.0+2992,0 -acodec pcm_s16le -vcodec libx264 -vpre lossless_ultrafast -threads 0 $RAW

echo Speeding up audio
mplayer -novideo -af scaletempo -speed $SPEED -ao pcm:fast:file=$FAST_AUDIO $RAW

echo Speeding up video
~/src/mplayer/mencoder -nosound $RAW -af scaletempo -speed $SPEED  -ovc x264 -o $FAST_VIDEO

echo Normalizing audio
normalize-audio $FAST_AUDIO

echo Compressing audio and video
ffmpeg -i $FAST_AUDIO -acodec libfaac -ab 128k -ac 2 -vcodec libx264 -vpre hq -crf 22 -threads 0 $COMP_AUDIO
ffmpeg -i $FAST_VIDEO -vcodec libx264 -vpre hq -crf 22 -threads 0 $COMP_VIDEO

echo Combining audio and video
MP4Box -add $COMP_AUDIO"#audio" $DEST
MP4Box -add $COMP_VIDEO"#video" $DEST

echo Deleting temporary files
rm $FAST_AUDIO $FAST_VIDEO $COMP_AUDIO $COMP_VIDEO

echo Done, see $DEST and $RAW
