#!/usr/bin/env bash

usage() {
	echo "USAGE: $0
		-p prototxt
		-c caffemodel
		-l layer
		-i input
		-o output
		[-f frames]
		[-d delay]
		[-n iterations per frame]";
}

delay=18
frames=8
iterations=5

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
		n) iterations=$OPTARG ;;
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

for i in `seq $frames`
do
	j=$((iterations * i))

	python3 ${script} \
		-p ${prototxt} \
		-c ${caffemodel} \
		-l ${layer} \
		-n ${j} \
		-i ${input} \
		-o tmp_${i}_${input}
done

convert \
	-delay ${delay} \
	-loop 0 \
	${input} \
	tmp_*_${input} \
	${output}

for i in `seq $frames`
do
	rm tmp_${i}_${input}
done

echo "done."
