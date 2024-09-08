#!/bin/bash
cd "$(dirname "$0")"
source ./script/setup.sh

export XCODEGEN_AEROSPACE_CODE_SIGN_IDENTITY="aerospace-codesign-certificate"
build_version="0.0.0-SNAPSHOT"
generate_xcodeproj=1
all=0
while [[ $# -gt 0 ]]; do
    case $1 in
        --build-version) build_version="$2"; shift 2 ;;
        --codesign-identity) XCODEGEN_AEROSPACE_CODE_SIGN_IDENTITY="$2"; shift 2 ;;
        --ignore-xcodeproj) generate_xcodeproj=0; shift 1 ;;
        --all) all=1; shift 1 ;;
        *) echo "Unknown option $1"; exit 1 ;;
    esac
done

if test $all = 1 && test $generate_xcodeproj = 0; then
    echo "./generate.sh: --all and --ignore-xcodeproj are conflicting" > /dev/stderr
    exit 1
fi

if test $all = 1; then
    # Grammar is not expected to change very often, that's why it's not regenerated by default
    ./generate-shell-parser.sh
fi

cat > Sources/Common/versionGenerated.swift <<EOF
// FILE IS GENERATED BY generate.sh
public let aeroSpaceAppVersion = "$build_version"
EOF

entries() {
    for file in docs/aerospace-*.adoc; do
        if grep -q 'exec-and-forget' <<< $file; then
            continue
        fi
        subcommand=$(basename $file | sed 's/^aerospace-//' | sed 's/\.adoc$//')
        desc="$(grep :manpurpose: $file | sed -E 's/:manpurpose: //')"
        echo "    [\"  $subcommand\", \"$desc\"],"
    done
}

cat <<EOF > ./Sources/Cli/subcommandDescriptionsGenerated.swift
// FILE IS GENERATED BY generate.sh
let subcommandDescriptions = [
$(entries)
]
EOF

cat <<EOF > ./Sources/Common/gitHashGenerated.swift
// FILE IS GENERATED BY generate.sh AND AUTO-UPDATED BY build-release.sh
public let gitHash = "SNAPSHOT"
public let gitShortHash = "SNAPSHOT"
EOF

if test $generate_xcodeproj = 1; then
    export XCODEGEN_AEROSPACE_VERSION=$build_version
    ./script/install-dep.sh --xcodegen
    ./.deps/swift-exec-deps/xcodegen # https://github.com/yonaskolb/XcodeGen
fi
