#!/bin/bash -x

workspace=`realpath $(dirname $0)`

# $1: filename (without extension)
# $2: gif-prefix

#mkdir -p $1
#
#files=""
#
#for angle in $(seq 0 20 340); do
#    hue=$(expr \( 100 \+ 100 \* $angle / 180 \) % 200)
#    convert $1.png -modulate 100,100,$hue -alpha set \( +clone -background none -rotate $angle \) -gravity center -compose Src -composite +dither -colors 32 $1/$1_$angle.png
#    files+=" $1/$1_$angle.png";
#done
#
#convert -loop 0 -page +0+0 $files -set dispose background -set delay 4 $1loko.gif
#gifsicle -O2 --colors 128 $1loko.gif -o $1loko.opt.gif

SLACK_MAX_WIDTH=128

assemble_gif() {
	echo "TODO"
}

cut_to_tiles() {
	image_path=$1
	num_tiles=$2
	tile_width=$3

	image_filename=$(basename $image_path)
	image_name=${image_filename%.*}
	image_fmt=${image_filename##*.}

	tmp_path=$workspace/$image_name
	mkdir -p $tmp_path/tiles$2

	resized_filename=$tmp_path/${image_name}_resized.$image_fmt
	resized_side=$(expr $num_tiles \* $tile_width)
	resized_dimensions=$(printf "%dx%d" $resized_side $resized_side)
	tile_dimensions=$(printf "%dx%d" $tile_width $tile_width)
	tile_directory=$tmp_path/tiles$2

	convert $image_path \
		-resize "$resized_dimensions!" $resized_filename
	convert $resized_filename \
		-crop $tile_dimensions $tile_directory/${image_name}_%02d.$image_fmt
}

megafy() {
	cut_to_tiles $1 2 $SLACK_MAX_WIDTH
}

gigafy() {
	cut_to_tiles $1 3 $SLACK_MAX_WIDTH
}

terafy() {
	cut_to_tiles $1 4 $SLACK_MAX_WIDTH
}

lokify() {
	echo "TODO"
}

megalokify() {
	echo "TODO"
}

gigalokify() {
	echo "TODO"
}

teralokify() {
	echo "TODO"
}

lokolokify() {
	echo "TODO"
}

print_usage() {
	echo "TODO"
}

command_=$1
shift

case $command_ in
	megafy|gigafy|terafy|lokify|megalokify|gigalokify|teralokify|lokolokify)
		echo "$command_ $*"
		$command_ $*
	;;
	*) print_usage ;;
esac
