#!/usr/bin/env bash

DATA=`pwd`/`dirname $0`
PTH=~/neural/neural-doodle

cd $PTH

python3 doodle.py \
	--content ${DATA}/ex_01_in1.png \
	--style ${DATA}/ex_01_in2.png \
	--output ${DATA}/ex_01_out1.png \
	--device=cuda

python3 doodle.py \
	--content ${DATA}/ex_01_in2.png \
	--style ${DATA}/ex_01_in1.png \
	--output ${DATA}/ex_01_out2.png \
	--device=cuda
