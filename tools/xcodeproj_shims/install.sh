#!/bin/bash

# Install the runnable products so that Xcode can run it. This includes `.app`s,
# `.xctest`s, and also command line binaries.

# TODO: Lyft uses this script, because Xcode calls `ditto` on the `.swiftmodule`/`.swiftdoc` files of the top-level
# target.
# "$SRCROOT"/bazel/installers/xcode-artifacts.sh

set -eux

# Delete all logfiles that are older than 7 days
find $BAZEL_DIAGNOSTICS_DIR -type f -atime +7d -delete

case ${PRODUCT_TYPE} in
    com.apple.product-type.framework)
        input="bazel-bin/$BAZEL_BIN_SUBDIR/${TARGET_NAME}/${FULL_PRODUCT_NAME}"
        ;;
    com.apple.product-type.bundle.unit-test)
        input="bazel-bin/$BAZEL_BIN_SUBDIR/$TARGET_NAME.__internal__.__test_bundle_archive-root/$TARGET_NAME${WRAPPER_SUFFIX:-}"
        ;;
    com.apple.product-type.application)
        input="bazel-bin/$BAZEL_BIN_SUBDIR/${TARGET_NAME}_archive-root/Payload/$TARGET_NAME${WRAPPER_SUFFIX:-}"
        ;;
    *)
        echo "Error: Installing ${TARGET_NAME} of type ${PRODUCT_TYPE} is unsupported" >&2
        exit 1
        ;;
esac
output="$TARGET_BUILD_DIR/$FULL_PRODUCT_NAME"

mkdir -p "$(dirname "$output")"

if [[ -d $input ]]; then
    # Copy bundle contents, into the destination bundle.
    # This avoids self-nesting, like: Foo.app/Foo.app
    input+="/"
fi


rsync \
    --recursive --chmod=u+w --delete \
    "$input" "$output" > $BAZEL_DIAGNOSTICS_DIR/rsync-stdout-$DATE_SUFFIX.log 2> $BAZEL_DIAGNOSTICS_DIR/rsync-stderr-$DATE_SUFFIX.log

$BAZEL_INSTALLERS_DIR/lldb-settings.sh  > $BAZEL_DIAGNOSTICS_DIR/lldb-stdout-$DATE_SUFFIX.log 2> $BAZEL_DIAGNOSTICS_DIR/lldb-stderr-$DATE_SUFFIX.log

# Part of the build intermediary output will be swiftmodule files
# which XCode will use for indexing. Let's keep those.
$BAZEL_INSTALLERS_DIR/swiftmodules.sh > $BAZEL_DIAGNOSTICS_DIR/swiftmodules-stdout-$DATE_SUFFIX.log 2> $BAZEL_DIAGNOSTICS_DIR/swiftmodules-stderr-$DATE_SUFFIX.log &
$BAZEL_INSTALLERS_DIR/indexstores.sh > $BAZEL_DIAGNOSTICS_DIR/indexstores-stdout-$DATE_SUFFIX.log 2> $BAZEL_DIAGNOSTICS_DIR/indexstores-stderr-$DATE_SUFFIX.log &


