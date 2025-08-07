#!/bin/bash
set -eo pipefail

type_arg=target

while [[ $# -gt 0 ]]; do
	case $1 in
	-c | --cache-dir) CACHE_DIR=${2%%/} && shift ;;
	-d | --docs-dir) DOCS_DIR=$2 && shift ;;
	-D | --diff-dir) DIFF_DIR=$2 && shift ;;
	-r | --ref) REF=$2 && shift ;;
	-f | --family) type_arg=family ;;
	*) TARGET_LIST="$TARGET_LIST $1" ;;
	esac
	shift
done

[[ -z $DOCS_DIR || -z $TARGET_LIST ]] && {
	echo "Usage: $0 -c <cache-dir> -d <docs-dir> [-D <diff-dir>] [-r <ref>] [--family] <target> [<target>...]" >&2
	exit 1
}

cleanup() {
	rm -f "$VERSION_SCRIPT" "$DOCS_SCRIPT"
}

mkdir -p "$DOCS_DIR"
[[ -n $DIFF_DIR ]] && mkdir -p "$DIFF_DIR"

VERSION_SCRIPT=./scripts/get_tlt_version.sh
DOCS_SCRIPT=./scripts/gen-desc.py

[[ -n $REF ]] && {
	cp "$VERSION_SCRIPT" "$DOCS_SCRIPT" ./
	VERSION_SCRIPT=./get_tlt_version.sh
	DOCS_SCRIPT=./gen-desc.py
	git checkout "$REF" || {
		cleanup
		exit 1
	}
}

CACHE_SUBDIR=${CACHE_DIR}/$(find config target/linux target/Config.in -type f -exec sha512sum {} + | sort | sha512sum | cut -d ' ' -f1)
mkdir -p "$CACHE_SUBDIR"

$VERSION_SCRIPT >/dev/null # dummy run to avoid version weirdness
VERSION_CURRENT=$($VERSION_SCRIPT | cut -d'_' -f2-)
VERSION_PREVIOUS_RELEASE=$($VERSION_SCRIPT --previous | cut -d'_' -f2-)

for TARGET in $TARGET_LIST; do
	FILE=${CACHE_SUBDIR}/${TARGET}.json
	[[ -f ${FILE} ]] || {
		$DOCS_SCRIPT --$type_arg "${TARGET}"
		mv "out/${TARGET}.json" "${FILE}"
	}

	FILE_LINK=${TARGET^^}_${VERSION_CURRENT}.json
	[[ -f $CACHE_DIR/$FILE_LINK ]] || ln -fs "${FILE#"$CACHE_DIR/"}" "$CACHE_DIR/$FILE_LINK"

	cp "${CACHE_DIR}/$FILE_LINK" "${DOCS_DIR}/" # save to artifacts

	[[ -n $DIFF_DIR ]] || continue

	export PREVIOUS_F=${TARGET^^}_${VERSION_PREVIOUS_RELEASE}.json
	[[ -f $CACHE_DIR/$PREVIOUS_F ]] || {
		echo "Docs for previous version $PREVIOUS_F not found for ${TARGET}, skipping diff generation"
		continue
	}

	export DIFF_FILE=${DIFF_DIR}/${PREVIOUS_F%.json}-${VERSION_CURRENT}.diff
	json-diff --sort "${CACHE_DIR}/${PREVIOUS_F}" "${DOCS_DIR}/${FILE_LINK}" >"$DIFF_FILE" || true
	sed -i -E -e '/^\s+\.\.\.$/d' "$DIFF_FILE"
done

[[ -z $REF ]] || {
	git checkout -
	cleanup
}
