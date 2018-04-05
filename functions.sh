#!/bin/bash

SCRIPTDIR=$(readlink -f "$(dirname "$0")")

load_tags () {
	local pkgdef=$1
	local tagcache=$2
	mkdir -p "$tagcache"
	while read package_name; do
		local url="https://api.github.com/repos/bunsenlabs/${package_name}/tags"
		echo -n "$FUNCNAME: $package_name ... "
		curl -s "$url" > "${tagcache}/${package_name}.json" && echo ok || echo fail
	done < "$pkgdef"
}

load_tarballs () {
	local tagcache=$1
	local tarballcache=$2
	mkdir -p "$tarballcache"
	for package_tags in "$tagcache"/*.json ; do
		local package_name=${package_tags%.json}
		package_name=${package_name##*/}
		local package_ver=$(jq -r '.[0].name' "$package_tags")
		local tarball_url=$(jq -r '.[0].tarball_url' "$package_tags")
		local commit=$(jq -r '.[0].commit.sha' "$package_tags")
		local tarball_name="${package_name}_${package_ver%-*}.orig.tar.gz"
		echo -n "$FUNCNAME: ${package_name}@${package_ver} ... "
		curl -L -s -o "$tarballcache/${tarball_name}" "$tarball_url" && echo ok || echo fail
	done
}

build_packages () {
	local tarballcache=$1
	local arch=$2
	local baseimage=$3
	local resultdir=$(readlink -f "$4")
	mkdir -p "$resultdir"
	for tarball in "$tarballcache"/*.tar.gz; do
		echo "$FUNCNAME: $tarball"
		local basename=${tarball%%_*}
		basename=${basename##*/}
		local outdir="${tarballcache}/$basename"
		mkdir -p "$outdir"	
		tar --strip-components=1 -xf "${tarball}" -C "$outdir"
		pushd "$PWD" &>/dev/null
		cd "$outdir"
		sudo pdebuild \
			--architecture "$arch" \
			--buildresult "$resultdir" \
			--pbuildersatisfydepends /usr/lib/pbuilder/pbuilder-satisfydepends-aptitude \
			--debbuildopts  -sa -- \
			--basetgz "$baseimage"
		popd &>/dev/null
	done
}
