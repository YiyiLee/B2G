#!/bin/bash
export REPO=$PWD/repo
export B2G_TREEID_SH="$PWD/profiling/patches/treeid.sh"
export B2G_HASHED_FILES="$PWD/profiling/patches/vendorsetup.sh ${B2G_TREEID_SH} $PWD/.config $PWD/profiling/patches/patch.sh"
export B2G_PATCH_DIRS_OVERRIDE=profiling/patches

. profiling/patches/vendorsetup.sh $1 force
