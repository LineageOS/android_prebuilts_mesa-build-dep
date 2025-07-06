#!/bin/bash

SRC_BIN_DIR=$1

if [ ! -d "$SRC_BIN_DIR" ]; then
	echo "Please specify source bin directory"
	exit 1
fi

cd $(dirname $(realpath $0))

for f in intel_clc mesa_clc vtn_bindgen vtn_bindgen2; do
	cp $SRC_BIN_DIR/$f ${f}.real || continue
	rm $f
	ln -s mesa-clc_wrapper $f
done
