#!/bin/bash
TMP_DIR="/tmp/tmpinstalldir"
function cleanup {
	echo rm -rf $TMP_DIR > /dev/null
}
function fail {
	cleanup
	msg=$1
	echo "============"
	echo "Error: $msg" 1>&2
	exit 1
}
function install {
	#settings
	BASE_URL="https://github.com/boypt/simple-torrent"
	if [ -z "$1" ]
	then
		LATEST_TAG=$(curl -s "${BASE_URL}/releases/latest" | sed -En 's/.+\/tag\/([.0-9A-Za-z]+)".+/\1/p')
	else
		LATEST_TAG="$1"
	fi
	USER="boypt"
	PROG="cloud-torrent"
	MOVE="true"
	RELEASE="$LATEST_TAG"
	INSECURE="false"
	OUT_DIR="/usr/local/bin"
	GH="https://github.com"
	#bash check
	[ ! "$BASH_VERSION" ] && fail "Please use bash instead"
	[ ! -d $OUT_DIR ] && fail "output directory missing: $OUT_DIR"
	#dependency check, assume we are a standard POISX machine
	which find > /dev/null || fail "find not installed"
	which xargs > /dev/null || fail "xargs not installed"
	which sort > /dev/null || fail "sort not installed"
	which tail > /dev/null || fail "tail not installed"
	which cut > /dev/null || fail "cut not installed"
	which du > /dev/null || fail "du not installed"
	GET=""
	if which curl > /dev/null; then
		GET="curl"
		if [[ $INSECURE = "true" ]]; then GET="$GET --insecure"; fi
		GET="$GET --fail -# -L"
	elif which wget > /dev/null; then
		GET="wget"
		if [[ $INSECURE = "true" ]]; then GET="$GET --no-check-certificate"; fi
		GET="$GET -qO-"
	else
		fail "neither wget/curl are installed"
	fi
	#find OS #TODO BSDs and other posixs
	case `uname -s` in
	Darwin) OS="darwin";;
	Linux) OS="linux";;
	*) fail "unknown os: $(uname -s)";;
	esac
	#find ARCH
	if uname -m | grep 64 > /dev/null; then
		ARCH="amd64"
	elif uname -m | grep arm > /dev/null; then
		ARCH="arm"
	elif uname -m | grep 386 > /dev/null; then
		ARCH="386"
	else
		fail "unknown arch: $(uname -m)"
	fi
	#choose from asset list
	URL=""
	FTYPE=""
	case "${OS}_${ARCH}" in
	"darwin_amd64")
		URL="https://github.com/boypt/simple-torrent/releases/download/$LATEST_TAG/cloud-torrent_linux_amd64.gz"
		FTYPE=".gz"
		;;
	"linux_386")
		URL="https://github.com/boypt/simple-torrent/releases/download/$LATEST_TAG/cloud-torrent_linux_386.gz"
		FTYPE=".gz"
		;;
	"linux_amd64")
		URL="https://github.com/boypt/simple-torrent/releases/download/$LATEST_TAG/cloud-torrent_linux_amd64.gz"
		FTYPE=".gz"
		;;
	"linux_arm")
		URL="https://github.com/boypt/simple-torrent/releases/download/$LATEST_TAG/cloud-torrent_linux_arm.gz"
		FTYPE=".gz"
		;;
	*) fail "No asset for platform ${OS}-${ARCH}";;
	esac
	#got URL! download it...
	echo "Installing $USER/$PROG $RELEASE..."
	#enter tempdir
	mkdir -p $TMP_DIR
	cd $TMP_DIR
	if [[ $FTYPE = ".gz" ]]; then
		which gzip > /dev/null || fail "gzip is not installed"
		#gzipped binary
		NAME="${PROG}_${OS}_${ARCH}.gz"
		GZURL="$GH/releases/download/$RELEASE/$NAME"
		#gz download!
		bash -c "$GET $URL" | gzip -d - > $PROG || fail "download failed"
	elif [[ $FTYPE = ".tar.gz" ]] || [[ $FTYPE = ".tgz" ]]; then
		#check if archiver progs installed
		which tar > /dev/null || fail "tar is not installed"
		which gzip > /dev/null || fail "gzip is not installed"
		bash -c "$GET $URL" | tar zxf - || fail "download failed"
	elif [[ $FTYPE = ".zip" ]]; then
		which unzip > /dev/null || fail "unzip is not installed"
		bash -c "$GET $URL" > tmp.zip || fail "download failed"
		unzip -o -qq tmp.zip || fail "unzip failed"
		rm tmp.zip || fail "cleanup failed"
	elif [[ $FTYPE = "" ]]; then
		bash -c "$GET $URL" > "cloud-torrent_${OS}_${ARCH}" || fail "download failed"
	else
		fail "unknown file type: $FTYPE"
	fi
	#search subtree largest file (bin)
	TMP_BIN=$(find . -type f | xargs du | sort -n | tail -n 1 | cut -f 2)
	if [ ! -f "$TMP_BIN" ]; then
		fail "could not find downloaded binary"
	fi
	#ensure its larger than 2MB
	if [[ $(du -m $TMP_BIN | cut -f1) -lt 2 ]]; then
		fail "resulting file is smaller than 2MB, not a go binary"
	fi
	#move into PATH or cwd
	chmod +x $TMP_BIN || fail "chmod +x failed"
	mv $TMP_BIN $OUT_DIR/$PROG || fail "mv failed" #FINAL STEP!
	echo "Installed at $OUT_DIR/$PROG"
	#done
	cleanup
}
install "$1"
