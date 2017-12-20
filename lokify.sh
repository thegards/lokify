#!/bin/bash

# $1: filename (without extension)

mkdir -p $1

files=""

for angle in $(seq 0 20 340); do
    hue=$(expr \( 100 \+ 100 \* $angle / 180 \) % 200)
    convert $1.png -modulate 100,100,$hue -alpha set \( +clone -background none -rotate $angle \) -gravity center -compose Src -composite +dither -colors 32 $1/$1_$angle.png
    files+=" $1/$1_$angle.png";
done

convert -loop 0 -page +0+0 $files -set dispose background -set delay 4 $1loko.gif
gifsicle -O2 --colors 128 $1loko.gif -o $1loko.opt.gif
