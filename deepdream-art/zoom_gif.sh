#!/usr/bin/env bash

usage() {
	echo "USAGE: $0
		-p prototxt
		-c caffemodel
		-l layer
		-i input
		-o output
		[-f frames]
		[-d delay]";
}

delay=18
frames=12

script=dream.py

while getopts "p:c:l:i:o:f:d:h" arg
do
	case $arg in
		p) prototxt=$OPTARG ;;
		c) caffemodel=$OPTARG ;;
		l) layer=$OPTARG ;;
		i) input=$OPTARG ;;
		o) output=$OPTARG ;;
		f) frames=$OPTARG ;;
		d) delay=$OPTARG ;;
		h) usage; exit ;;
		*) usage; exit 1 ;;
	esac
done

if [[ -z "${prototxt}" ]] || \
	[[ -z "${caffemodel}" ]] || \
	[[ -z "${layer}" ]] || \
	[[ -z "${input}" ]] || \
	[[ -z "${output}" ]]
	then usage; exit 1;
fi

w=`convert ${input} -format "%w" info:`
h=`convert ${input} -format "%h" info:`

n=$((frames - 1))

python3 ${script} \
	-p ${prototxt} \
	-c ${caffemodel} \
	-l ${layer} \
	-i ${input} \
	-o tmp_dream_0_${input}

for i in `seq $n`
do
	wi=$(((w / frames) * (frames - i)))
	hi=$(((h / frames) * (frames - i)))

	echo ${i}, ${wi}, ${hi}

	convert ${input} \
		-gravity center \
		-crop ${wi}x${hi}+0+0 \
		-resize ${w}x${h} \
		+repage \
		-colorspace sRGB \
		-type truecolor \
		-define png:color-type=2 \
		tmp_${i}_${input}

	python3 ${script} \
		-p ${prototxt} \
		-c ${caffemodel} \
		-l ${layer} \
		-i tmp_${i}_${input} \
		-o tmp_dream_${i}_${input}

	rm tmp_${i}_${input}
done

lst=()

for i in `seq $frames`
do
	j=$((i - 1))
	lst[$i]='tmp_dream_'${j}'_'${input}
done

convert \
	-delay ${delay} \
	-loop 0 \
	${input} \
	${lst[@]} \
	${output}

rm ${lst[@]}

echo "done."
