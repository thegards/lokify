#!/bin/bash -x

SLACK_MAX_WIDTH=128

workspace=`realpath $(dirname $0)`

assemble_gif() {
	image_name=$1
	search_pattern=$2
	workdir=$3

	files=$(find -name "$search_pattern" ${workdir} | sort)
	convert -loop 0 -page +0+0 ${files} -set dispose background -set delay 4 \
		${image_name}_loko.gif
	#gifsicle -O2 --colors 128 $1loko.gif -o $1loko.opt.gif
}

generate_rotations() {
	image_path=$1
	output_dir=$2

	image_filename=$(basename ${image_path})
	image_name=${image_filename%.*}
	image_fmt=${image_filename##*.}

	mkdir -p ${output_dir}

	for angle in $(seq 0 20 340); do
		hue=$(expr \( 100 \+ 100 \* ${angle} / 180 \) % 200)
		convert ${image_path} \
			-modulate 100,100,${hue} \
			-alpha set \( +clone -background none -rotate ${angle} \) \
			-gravity center -compose Src -composite +dither -colors 32 \
			${output_dir}/${image_name}_$(printf "%03d" ${angle}).${image_fmt}
	done
}

cut_to_tiles() {
	image_path=$1
	grid_size=$2
	tile_width=$3
	output_dir=$4

	image_filename=$(basename ${image_path})
	image_name=${image_filename%.*}
	image_fmt=${image_filename##*.}

	tile_dimensions=$(printf "%dx%d" ${tile_width} ${tile_width})
	resized_side=$(expr ${grid_size} \* ${tile_width})
	resized_dimensions=$(printf "%dx%d" ${resized_side} ${resized_side})

	if [ -z ${output_dir} ];
	then
		output_dir=${workspace}/${image_name}
		tile_directory=${output_dir}/tiles$2
	else
		tile_directory=${output_dir}
	fi

	mkdir -p ${output_dir}
	mkdir -p ${tile_directory}

	resized_filename=${output_dir}/${image_name}_${resized_dimensions}.${image_fmt}
	convert ${image_path} \
		-resize "${resized_dimensions}!" ${resized_filename}

	convert ${resized_filename} \
		-crop ${tile_dimensions} \
		-set filename:tile "%[fx:page.y/${tile_width}]%[fx:page.x/${tile_width}]" \
		+repage +adjoin \
		"${tile_directory}/${image_name}_%[filename:tile].${image_fmt}"
}

resize_image() {
}

anyfy() {
	image_path=$1
	grid_size=$2

	resized_size=
	output_size=

	resize_image ${image_path} ${resized_size} ${output_path}
	cut_to_tiles ${resized_image_path} ${grid_size} ${SLACK_MAX_WIDTH}
}

megafy() {
	anyfy $1 2
}

gigafy() {
	anyfy $1 3
}

terafy() {
	anyfy $1 4
}

lokify() {
	#$1: filename (without extension)
	#$2: gif-prefix

	mkdir -p $1

	files=""

	for angle in $(seq 0 20 340); do
		hue=$(expr \( 100 \+ 100 \* ${angle} / 180 \) % 200)
		convert $1.png -modulate 100,100,${hue} -alpha set \( +clone -background none -rotate ${angle} \) -gravity center -compose Src -composite +dither -colors 32 $1/$1_${angle}.png
		files+=" $1/$1_${angle}.png";
	done

	convert -loop 0 -page +0+0 ${files} -set dispose background -set delay 4 $1loko.gif
	gifsicle -O2 --colors 128 $1loko.gif -o $1loko.opt.gif
}

anylokify() {
	image_path=$1
	grid_size=$2

	image_filename=$(basename ${image_path})
	image_name=${image_filename%.*}
	image_fmt=${image_filename##*.}

	rotations_output=${workspace}/${image_name}_$2lokify
	mkdir -p ${rotations_output}



	generate_rotations ${image_path} ${rotations_output}

	for img in $(find *.png ${rotations_output} | sort);
	do
		cut_to_tiles ${img} ${grid_size} ${SLACK_MAX_WIDTH} ${rotations_output}
	done

	for row in $(seq 0 1 ${grid_size});
	do
		for col in $(seq 0 1 ${grid_size});
		do
			assemble_gif "${image_name}_${row}${col}" "${image_name}_*_${row}${col}.png" ${rotations_output}
		done
	done
}

megalokify() {
	anylokify $1 2
}

gigalokify() {
	anylokify $1 3
}

teralokify() {
	anylokify $1 4
}

lokolokify() {
	echo "TODO"
}

print_usage() {
	echo "TODO"
}

command_=$1
shift

case ${command_} in
	megafy|gigafy|terafy|lokify|megalokify|gigalokify|teralokify|lokolokify)
		${command_} $*
	;;
	*) print_usage ;;
esac
