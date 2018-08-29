#!/bin/bash

SLACK_MAX_WIDTH=100
SLACK_MAX_HEIGHT=100

workspace=`realpath $(pwd)`

assemble_gif() {
	local image_prefix=$1
	local image_suffix=$2
	local search_pattern=$3
	local workdir=$4
	local output_dir=$5

	mkdir -p ${output_dir}

	local files=$(find ${workdir} -regex "$search_pattern" | sort)
	convert -loop 0 -page +0+0 ${files} -set dispose background -set delay 4 \
		${output_dir}/${image_prefix}-loko-nopt-${image_suffix}.gif
	gifsicle -O2 --colors 128 \
		${output_dir}/${image_prefix}-loko-nopt-${image_suffix}.gif \
		-o ${output_dir}/${image_prefix}-loko-${image_suffix}.gif
	rm ${output_dir}/*-loko-nopt-*.gif
}

generate_rotations() {
	local image_path=$1
	local image_prefix=$2
	local output_dir=$3

	local image_filename=$(basename ${image_path})
	local image_name=${image_filename%.*}
	local image_fmt=${image_filename##*.}

	mkdir -p ${output_dir}

	for angle in $(seq 0 20 340); do
		local hue=$(expr \( 100 \+ 100 \* ${angle} / 180 \) % 200)
		convert ${image_path} \
			-modulate 100,100,${hue} \
			-alpha set \( +clone -background none -rotate ${angle} \) \
			-gravity center -compose Src -composite +dither -colors 32 \
			${output_dir}/${image_prefix}-$(printf "%03d" ${angle}).${image_fmt}
	done
}

cut_to_tiles() {
	local image_path=$1
	local image_prefix=$2
	local grid_width=$3
	local grid_height=$4
	local tile_width=$5
	local tile_height=$6
	local output_dir=$7

	local image_filename=$(basename ${image_path})
	local image_name=${image_filename%.*}
	local image_fmt=${image_filename##*.}

	if [ "x${image_prefix}" == "x" ];
	then
		image_prefix=${image_name}
	fi

	local tile_dimensions=$(printf "%dx%d" ${tile_width} ${tile_height})

	mkdir -p ${output_dir}

	convert ${image_path} \
		-crop ${tile_dimensions} \
		-set filename:tile "%[fx:page.y/${tile_height}]%[fx:page.x/${tile_width}]" \
		+repage +adjoin \
		"${output_dir}/${image_prefix}-%[filename:tile].${image_fmt}"
}

resize_image() {
	local image_path=$1
	local resized_dimensions=$2
	local resized_filename=$3

	convert ${image_path} \
		-gravity Center -resize "${resized_dimensions}^" \
		-crop "${resized_dimensions}+0+0" \
		${resized_filename}
}

anyfy() {
	local image_path=$1
	local grid_width=$2
	local grid_height=$3

	local image_filename=$(basename ${image_path})
	local image_name=${image_filename%.*}
	local image_fmt=${image_filename##*.}

	local output_dir=${workspace}/${image_name}-${grid_width}x${grid_height}fy

	local resized_width=$(expr ${grid_width} \* ${SLACK_MAX_WIDTH})
	local resized_height=$(expr ${grid_height} \* ${SLACK_MAX_HEIGHT})
	local resized_dimensions=$(printf "%dx%d" ${resized_width} ${resized_height})
	local resized_filename=${output_dir}/${image_name}-${resized_dimensions}.${image_fmt}

	mkdir -p ${output_dir}

	resize_image ${image_path} ${resized_dimensions} ${resized_filename}
	cut_to_tiles ${resized_filename} ${image_name} ${grid_width} ${grid_height} \
		${SLACK_MAX_WIDTH} ${SLACK_MAX_HEIGHT} ${output_dir}
}

megafy() {
	anyfy $1 2 2
}

gigafy() {
	anyfy $1 3 3
}

terafy() {
	anyfy $1 4 4
}

fontify() {
	anyfy $1 3 5
}

anylokify() {
	local image_path=$1
	local grid_width=$2
	local grid_height=$3

	local image_filename=$(basename ${image_path})
	local image_name=${image_filename%.*}
	local image_fmt=${image_filename##*.}

	local output_dir=${workspace}/${image_name}-${grid_size}lokify
	mkdir -p ${output_dir}

	local resized_width=$(expr ${grid_width} \* ${SLACK_MAX_WIDTH})
	local resized_height=$(expr ${grid_height} \* ${SLACK_MAX_HEIGHT})
	local resized_dimensions=$(printf "%dx%d" ${resized_width} ${resized_height})
	local resized_filename=${output_dir}/${image_name}-${resized_dimensions}.${image_fmt}

	resize_image ${image_path} ${resized_dimensions} ${resized_filename}
	generate_rotations ${resized_filename} ${image_name} ${output_dir}

	for img in $(find ${output_dir} -regex ".*-[0-9][0-9][0-9]\.${image_fmt}" | sort);
	do
		cut_to_tiles ${img} "" ${grid_width} ${grid_height} ${SLACK_MAX_WIDTH} \
			${SLACK_MAX_HEIGHT} ${output_dir}
	done

	for row in $(seq 0 1 `expr ${grid_height} - 1`)
	do
		for col in $(seq 0 1 `expr ${grid_width} - 1`)
		do
			assemble_gif "${image_name}" "${row}${col}" \
				".*${image_name}-[0-9]+-${row}${col}\.${image_fmt}" \
				${output_dir} ${output_dir}
		done
	done
}

#lokify() {
#	#$1: filename (without extension)
#	#$2: gif-prefix
#
#	mkdir -p $1
#
#	local files=""
#
#	for angle in $(seq 0 20 340); do
#		local hue=$(expr \( 100 \+ 100 \* ${angle} / 180 \) % 200)
#		convert $1.png -modulate 100,100,${hue} -alpha set \( +clone -background none -rotate ${angle} \) -gravity center -compose Src -composite +dither -colors 32 $1/$1_${angle}.png
#		files+=" $1/$1_${angle}.png";
#	done
#
#	convert -loop 0 -page +0+0 ${files} -set dispose background -set delay 4 $1loko.gif
#	gifsicle -O2 --colors 128 $1loko.gif -o $1loko.opt.gif
#}

lokify() {
	anylokify $1 1 1
}

megalokify() {
	anylokify $1 2 2
}

gigalokify() {
	anylokify $1 3 3
}

teralokify() {
	anylokify $1 4 4
}

alanlokify() {
	anylokify $1 8 8
}

fontilokify() {
	anylokify $1 3 5
}

print_usage() {
	echo "TODO"
}

command_=$1
shift

case ${command_} in
	fontify|megafy|gigafy|terafy|lokify|alanlokify|\
	fontilokify|megalokify|gigalokify|teralokify)
		${command_} $*
	;;
	*) print_usage ;;
esac
