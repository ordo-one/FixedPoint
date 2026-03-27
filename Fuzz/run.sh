#!/usr/bin/env bash
# Build and optionally run the FixedPointDecimal libFuzzer fuzz target.
#
# Platform: Linux only — Swift's -sanitize=fuzzer requires the open-source
#           toolchain (not available in Xcode on macOS).
#
# Usage:
#   bash Fuzz/run.sh              # build only (release)
#   bash Fuzz/run.sh run          # build + run (Ctrl-C to stop)
#   bash Fuzz/run.sh run -max_total_time=60  # run for 60 seconds
#   bash Fuzz/run.sh debug        # build only (debug, for lldb)
#   bash Fuzz/run.sh debug run    # build debug + run
#
# Requirements: Swift 6.2+ open-source toolchain on Linux.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SRC_DIR="$REPO_DIR/Sources/FixedPointDecimal"
FUZZ_SRC="$SCRIPT_DIR/FixedPointDecimalFuzz.swift"
OUTPUT="$SCRIPT_DIR/fuzz-fixedpointdecimal"
CORPUS_DIR="$SCRIPT_DIR/corpus"

if [[ "$(uname)" != "Linux" ]]; then
    echo "Error: libFuzzer (-sanitize=fuzzer) requires the open-source Swift toolchain on Linux."
    echo "       It is not available in Xcode on macOS."
    exit 1
fi

# Collect all library sources (exclude SwiftUI-only file on Linux)
LIB_SOURCES=()
for f in "$SRC_DIR"/*.swift; do
    case "$(basename "$f")" in
        *SwiftUI*) ;; # Skip — requires SwiftUI (macOS/iOS only)
        *Macro*)   ;; # Skip — requires macro plugin (not available in single-module compilation)
        *) LIB_SOURCES+=("$f") ;;
    esac
done

DEBUG=false
if [[ "${1:-}" == "debug" ]]; then
    DEBUG=true
    shift
fi

echo "Building fuzz target..."
if $DEBUG; then
    echo "  (debug build with -g -Onone)"
    swiftc \
        -sanitize=fuzzer \
        -parse-as-library \
        -Onone \
        -g \
        -o "$OUTPUT" \
        "$FUZZ_SRC" \
        "${LIB_SOURCES[@]}"
else
    # Note: -whole-module-optimization is intentionally omitted. WMO inlines
    # library functions into the fuzz target, causing UBSan (bundled with
    # -sanitize=fuzzer) to instrument Swift's well-defined integer operations
    # with C-semantics overflow traps. Without WMO, library functions keep
    # their own boundaries and UBSan only instruments the fuzz harness.
    swiftc \
        -sanitize=fuzzer \
        -parse-as-library \
        -O \
        -o "$OUTPUT" \
        "$FUZZ_SRC" \
        "${LIB_SOURCES[@]}"
fi

echo "Built: $OUTPUT"

if [[ "${1:-}" == "run" ]]; then
    shift
    mkdir -p "$CORPUS_DIR"
    echo "Running fuzzer (Ctrl-C to stop)..."
    "$OUTPUT" "$CORPUS_DIR" "$@"
fi
