#!/bin/bash

# 1. `meson install -C builddir --destdir destdir`
# 2. `./.update.sh <mesa>/builddir/destdir`

SRC_BIN_DIR=$1

if [ ! -d "$SRC_BIN_DIR" ]; then
	echo "Please specify source bin directory"
	exit 1
fi

cd $(dirname $(realpath $0))

for f in mesa_clc panfrost_compile panfrostdump panfrost_texfeatures vtn_bindgen2; do
	cp $SRC_BIN_DIR/$f ${f}.real || continue
	rm $f
	ln -s .mesa-build-dep_wrapper $f
done
