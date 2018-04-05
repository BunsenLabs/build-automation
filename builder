#!/bin/bash

. "functions.sh"

arch=${arch:-amd64}

(( $do_load_tags )) && load_tags ./package.list ./tags
(( $do_load_tarballs )) && load_tarballs ./tags/ ./tarballs/
(( $do_build )) && build_packages ./tarballs/ "$arch" /var/cache/pbuilder/stretch_${arch}.tgz ./results/
