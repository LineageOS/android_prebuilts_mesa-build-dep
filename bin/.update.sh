#!/bin/bash

# 1. `meson install -C builddir --destdir destdir`
# 2. `./.update.sh <mesa>/builddir/destdir/usr/local/bin`

SRC_BIN_DIR=$1

if [ ! -d "$SRC_BIN_DIR" ]; then
	echo "Please specify source bin directory"
	exit 1
fi

cd $(dirname $(realpath $0))

BINS="afuc-asm
afuc-disasm
asahi_clc
aubinator
aubinator_error_decode
aubinator_viewer
brw_asm
brw_disasm
bsdcat
bsdcpio
bsdtar
computerator
crashdec
elk_asm
elk_disasm
generate_rd
intel_dev_info
intel_dump_gpu
intel_error2aub
intel_error2hangdump
intel_hang_replay
intel_hang_viewer
intel_measure.py
intel_monitor
intel_sanitize_gpu
intel_stub_gpu
mda
mesa_clc
panfrost_compile
panfrostdump
panfrost_texfeatures
pco_clc
rddecompiler
replay
spirv2nir
vtn_bindgen2"

for f in $BINS; do
	cp $SRC_BIN_DIR/$f ${f}.real || continue
	rm -f $f
	ln -s .mesa-build-dep_wrapper $f
done
