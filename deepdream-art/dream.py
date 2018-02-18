#!/usr/bin/env python3

# https://github.com/google/deepdream/blob/master/dream.ipynb

import os
import argparse

import caffe

import numpy as np
import scipy.ndimage as nd

import PIL.Image

from io import StringIO

from google.protobuf import text_format

def preprocess(net, img):
	return np.float32(np.rollaxis(img, 2)[::-1]) - net.transformer.mean['data']

def deprocess(net, img):
	return np.dstack((img + net.transformer.mean['data'])[::-1])

def objective_L2(dst):
	dst.diff[:] = dst.data 

def make_step(net, end, step_size=1.5, 
		jitter=32, clip=True, objective=objective_L2):

	src = net.blobs['data']
	dst = net.blobs[end]

	ox, oy = np.random.randint(-jitter, jitter + 1, 2)
	src.data[0] = np.roll(np.roll(src.data[0], ox, -1), oy, -2)
			
	net.forward(end=end)
	objective(dst)
	net.backward(start=end)
	g = src.diff[0]

	src.data[:] += step_size / np.abs(g).mean() * g

	src.data[0] = np.roll(np.roll(src.data[0], -ox, -1), -oy, -2)

	if clip:
		bias = net.transformer.mean['data']
		src.data[:] = np.clip(src.data, -bias, 255 - bias)

def deepdream(net, base_img, end, iter_n=10, octave_n=4, octave_scale=1.4,
		clip=True, **step_params):

	octaves = [preprocess(net, base_img)]

	for i in range(octave_n - 1):
		octaves.append(nd.zoom(octaves[-1],
			(1, 1.0 / octave_scale, 1.0 / octave_scale), order=1))

	src = net.blobs['data']
	detail = np.zeros_like(octaves[-1])

	for octave, octave_base in enumerate(octaves[::-1]):
		h, w = octave_base.shape[-2:]
		if octave > 0:
			h1, w1 = detail.shape[-2:]
			detail = nd.zoom(detail, (1, 1.0 * h / h1, 1.0 * w / w1), order=1)

		src.reshape(1, 3, h, w)
		src.data[0] = octave_base + detail

		for i in range(iter_n):
			make_step(net, end, clip=clip, **step_params)

		detail = src.data[0]-octave_base
	return deprocess(net, src.data[0])

def gen_img(prototxt, caffemodel, layer, iter_n, input_path, output_path):
	model = caffe.io.caffe_pb2.NetParameter()
	
	text_format.Merge(open( prototxt).read(), model)
	
	model.force_backward = True

	open('tmp.prototxt', 'w').write(str(model))

	net = caffe.Classifier('tmp.prototxt', caffemodel,
		mean = np.float32([104.0, 116.0, 122.0]),
		channel_swap = (2, 1, 0))

	img = np.float32(PIL.Image.open( input_path ))

	frame = deepdream(net, img, layer, iter_n=iter_n)

	PIL.Image.fromarray(np.uint8(frame)).save( output_path )

if __name__ == "__main__":

	parser = argparse.ArgumentParser()

	parser.add_argument('-p', '--prototxt', required=True)
	parser.add_argument('-c', '--caffemodel', required=True)
	parser.add_argument('-l', '--layer', required=True)

	parser.add_argument('-n', '--iter', default=30, type=int)

	parser.add_argument('-i', '--input', required=True)
	parser.add_argument('-o', '--output', required=True)

	args = parser.parse_args()

	gen_img(args.prototxt, args.caffemodel, args.layer, args.iter,
		args.input, args.output)
