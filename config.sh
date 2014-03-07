#!/bin/bash

REPO=${REPO:-./repo}
sync_flags=""

repo_sync() {
	rm -rf .repo/manifest* &&
	$REPO init -u $GITREPO -b $BRANCH -m $1.xml &&
	mv .repo/manifest.xml .repo/manifest.xml.original &&
	sed -e "s/http:\/\/sprdsource.spreadtrum.com:8085/http:\/\/sprd-tunnel.skunk-works.no:8022/g" .repo/manifest.xml.original > .repo/manifest.xml &&
	$REPO sync $sync_flags
	ret=$?
	if [ "$GITREPO" = "$GIT_TEMP_REPO" ]; then
		rm -rf $GIT_TEMP_REPO
	fi
	if [ $ret -ne 0 ]; then
		echo Repo sync failed
		exit -1
	fi
}

case `uname` in
"Darwin")
	# Should also work on other BSDs
	CORE_COUNT=`sysctl -n hw.ncpu`
	;;
"Linux")
	CORE_COUNT=`grep processor /proc/cpuinfo | wc -l`
	;;
*)
	echo Unsupported platform: `uname`
	exit -1
esac

GITREPO=${GITREPO:-"git://github.com/jld/b2g-manifest"}
BRANCH=${BRANCH:-profiling}

while [ $# -ge 1 ]; do
	case $1 in
	-d|-l|-f|-n|-c|-q|-j*)
		sync_flags="$sync_flags $1"
		if [ $1 = "-j" ]; then
			shift
			sync_flags+=" $1"
		fi
		shift
		;;
	--help|-h)
		# The main case statement will give a usage message.
		break
		;;
	-*)
		echo "$0: unrecognized option $1" >&2
		exit 1
		;;
	*)
		break
		;;
	esac
done

case "$1" in
sp*)
	echo "Spreadtrum device detected. Using spreadtrum repo for b2g-manifest"
	GITREPO=${GITREPO:-"git://github.com/sprd-ffos/b2g-manifest"}
	;;
*)  GITREPO=${GITREPO:-"git://github.com/mozilla-b2g/b2g-manifest"}
	;;
esac


use_local_manifest() {
	GITREPO=$GIT_TEMP_REPO
	rm -rf $GITREPO &&
	git init $GITREPO &&
	cp $2 $GITREPO/$1.xml &&
	cd $GITREPO &&
	git add $1.xml &&
	git commit -m "manifest" &&
	git branch -m $BRANCH &&
	cd ..
}

GIT_TEMP_REPO="tmp_manifest_repo"
if [ -n "$2" ]; then
	GITREPO=$GIT_TEMP_REPO
	rm -rf $GITREPO &&
	git init $GITREPO &&
	cp $2 $GITREPO/$1.xml &&
	cd $GITREPO &&
	git add $1.xml &&
	git commit -m "manifest" &&
	git branch -m $BRANCH &&
	cd ..
fi

echo MAKE_FLAGS=-j$((CORE_COUNT + 2)) > .tmp-config
echo GECKO_OBJDIR=$PWD/objdir-gecko >> .tmp-config
echo DEVICE_NAME=$1 >> .tmp-config

case "$1" in
"galaxy-s2")
	echo DEVICE=galaxys2 >> .tmp-config &&
	repo_sync $1
	;;

"galaxy-nexus")
	echo DEVICE=maguro >> .tmp-config &&
	repo_sync $1
	;;

"nexus-4")
	echo DEVICE=mako >> .tmp-config &&
	repo_sync nexus-4
	;;

"nexus-4-kk")
	echo DEVICE=mako >> .tmp-config &&
	repo_sync nexus-4-kk
	;;

"nexus-5")
  echo DEVICE=hammerhead >> .tmp-config &&
  repo_sync nexus-5
  ;;

"optimus-l5")
	echo DEVICE=m4 >> .tmp-config &&
	repo_sync $1
	;;

"nexus-s")
	echo DEVICE=crespo >> .tmp-config &&
	repo_sync $1
	;;

"nexus-s-4g")
	echo DEVICE=crespo4g >> .tmp-config &&
	repo_sync $1
	;;

"otoro"|"unagi"|"keon"|"inari"|"leo"|"hamachi"|"peak"|"helix"|"wasabi"|"flatfish")
	echo DEVICE=$1 >> .tmp-config &&
	repo_sync $1
	;;

"flame")
	echo PRODUCT_NAME=$1 >> .tmp-config &&
	case "$BRANCH" in
	"profiling")
		use_local_manifest flame "profiling_manifests/flame.xml"
		;;
	esac &&
       repo_sync $1
	;;

"fugu")
	echo DEVICE=fugu >> .tmp-config &&
	echo LUNCH=fugu-eng >> .tmp-config &&
	echo TARGET_HVGA_ENABLE=true >> .tmp-config &&
	echo GONK_VERSION=SP7710_13A_W13.39.7 >> .tmp-config &&
	repo_sync $1
	;;

"tarako")
	echo DEVICE=sp6821a_gonk >> .tmp-config &&
	echo LUNCH=sp6821a_gonk-userdebug >> .tmp-config &&
	repo_sync $1
	;;

"tara")
	echo DEVICE=sp8810ea >> .tmp-config &&
	echo LUNCH=sp8810eabase-eng >> .tmp-config &&
	repo_sync $1
	;;

"sprd-bootstrap")
	repo_sync $1
	;;

"sp6821a")
	echo DEVICE=sp6821a_gonk >> .tmp-config &&
	echo LUNCH=sp6821a_gonk-userdebug >> .tmp-config &&
	case "$BRANCH" in
	"v1.3"*)
		echo DEVICE_NAME=sp6821a_gonk4.0 >> .tmp-config
		BRANCH=sprd repo_sync sp6821a_gonk4.0
		;;
	"master")
		echo DEVICE_NAME=sp6821a_gonk4.0_master >> .tmp-config
		BRANCH=sprd repo_sync sp6821a_gonk4.0_master
		;;
	*)
		echo "Branch $BRANCH not supported for device $1"
		exit 1
		;;
	esac
	;;

"sp7710gaplus")
	echo DEVICE=sp7710gaplus_gonk >> .tmp-config &&
	echo LUNCH=sp7710gaplus_gonk-userdebug >> .tmp-config &&
	echo TARGET_HVGA_ENABLE=true >> .tmp-config &&
	echo GONK_VERSION=SP7710_13A_W13.39.7 >> .tmp-config &&
	case "$BRANCH" in
	"v1.3"*)
		echo DEVICE_NAME=sp7710gaplus_gonk4.0 >> .tmp-config
		BRANCH=sprd repo_sync sp7710ga_gonk4.0_v1.3
		;;
	"master")
		echo DEVICE_NAME=sp7710gaplus_gonk4.0_master >> .tmp-config
		BRANCH=sprd repo_sync sp7710ga_gonk4.0_master
		;;
	"profiling")
		echo DEVICE_NAME=sp7710gaplus_gonk4.0_master >> .tmp-config
		use_local_manifest "sp7710ga_gonk4.0_master" "profiling_manifests/sp7710ga_gonk4.0_master.xml"
		repo_sync sp7710ga_gonk4.0_master
		;;
	*)
		echo "Branch $BRANCH not supported for device $1"
		exit 1
		;;
	esac
	;;

"sp7715ga")
	echo DEVICE=scx15_sp7715ga >> .tmp-config &&
	echo LUNCH=scx15_sp7715gaplus-userdebug >> .tmp-config &&
	case "$BRANCH" in
	"v1.4")
		echo DEVICE_NAME=sp7715ga_gonk4.4 >> .tmp-config &&
		BRANCH=sprd repo_sync sp7715ga_gonk4.4
		;;
	"profiling")
		echo DEVICE_NAME=sp7715ga_gonk4.4 >> .tmp-config &&
		use_local_manifest "sp7715ga_gonk4.4" "profiling_manifests/sp7715ga_gonk4.4" &&
		repo_sync sp7715ga_gonk4.4
		;;
	*)
		echo "Branch $BRANCH not supported for device $1"
		exit 1
		;;
	esac

"dolphin")
	echo DEVICE=scx15_sp7715ga >> .tmp-config &&
	echo PRODUCT_NAME=scx15_sp7715gaplus >> .tmp-config &&
	repo_sync $1
	;;

"pandaboard")
	echo DEVICE=panda >> .tmp-config &&
	repo_sync $1
	;;

"emulator"|"emulator-jb"|"emulator-kk")
	echo DEVICE=generic >> .tmp-config &&
	echo LUNCH=full-eng >> .tmp-config &&
	repo_sync $1
	;;

"emulator-x86"|"emulator-x86-jb"|"emulator-x86-kk")
	echo DEVICE=generic_x86 >> .tmp-config &&
	echo LUNCH=full_x86-eng >> .tmp-config &&
	repo_sync $1
	;;

"flo")
	echo DEVICE=flo >> .tmp-config &&
	repo_sync $1
	;;

*)
	echo "Usage: $0 [-cdflnq] (device name)"
	echo "Flags are passed through to |./repo sync|."
	echo
	echo Valid devices to configure are:
	echo - galaxy-s2
	echo - galaxy-nexus
	echo - nexus-4
	echo - nexus-4-kk
	echo - nexus-5
	echo - nexus-s
	echo - nexus-s-4g
	echo - flo "(Nexus 7 2013)"
	echo - otoro
	echo - unagi
	echo - inari
	echo - keon
	echo - peak
	echo - leo
	echo - hamachi
	echo - helix
	echo - wasabi
	echo - fugu
	echo - tarako
	echo - tara
	echo - sprd-bootstrap = Bootstrap sprd devices from non-Chinese sources
	echo - sp6821a ======== 128M RAM, v1.3 and master -- Use branch v1.3 for now!
	echo - sp7710gaplus === Dual SIM, v1.3 and master
	echo - sp7715ga ======= Dual SIM, v1.4
	echo - dolphin
	echo - pandaboard
	echo - flatfish
	echo - flame
	echo - emulator
	echo - emulator-jb
	echo - emulator-kk
	echo - emulator-x86
	echo - emulator-x86-jb
	echo - emulator-x86-kk
	exit -1
	;;
esac

if [ $? -ne 0 ]; then
	echo Configuration failed
	exit -1
fi

mv .tmp-config .config

echo Run \|./build.sh\| to start building
