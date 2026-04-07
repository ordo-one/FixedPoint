# Updating External Test Suites

This directory contains test vectors from three external decimal arithmetic test suites.
Below are instructions for updating each when new versions are released.

## General Decimal Arithmetic (GDA) -- Speleotrove/Cowlishaw

**Current version:** 2.62 (as of 2026-04)
**Source:** https://speleotrove.com/decimal/dectest.zip
**License:** ICU License (see GDA/LICENSE)

To update:
1. Download: `curl -O https://speleotrove.com/decimal/dectest.zip`
2. Extract: `unzip -o dectest.zip -d GDA/` (overwrites existing files)
3. Verify the `version:` directive in test files matches the expected version
4. Run `swift test --filter GDA` to verify all supported-operation tests still pass
5. Check skip counts -- a significant change may indicate new test cases worth reviewing

## Fahmy Arithmetic Test Vectors -- Cairo University

**Current version:** 2011 (latest files dated 2011-11)
**Source:** http://eece.cu.edu.eg/~hfahmy/arith_debug/
**License:** Permissive with attribution (see Fahmy/LICENSE)

The vendored files are pre-filtered subsets of the full archives. The full archives
contain hundreds of thousands of vectors with exponents spanning the decimal64 range
(E-398 to E+369), but only ~1-2% of vectors have exponents compatible with our
representable range (8 fractional digits, ~92 billion max). Pre-filtering keeps the
repository small while retaining all compatible vectors.

To update:
1. Download individual zip files (no single archive):
   ```bash
   curl --connect-timeout 30 -O http://eece.cu.edu.eg/~hfahmy/arith_debug/2010_07_d64_add.zip
   curl --connect-timeout 30 -O http://eece.cu.edu.eg/~hfahmy/arith_debug/2010_07_d64_mul.zip
   curl --connect-timeout 30 -O http://eece.cu.edu.eg/~hfahmy/arith_debug/2011_03_d64_div.zip
   ```
2. Verify checksums against the `.md5sum` files on the same page
3. Extract and pre-filter to vectors with exponents in [-24, 2] range:
   ```python
   import re, os
   def filter_by_exponent_range(input_dir, output_file):
       with open(output_file, 'w') as out:
           for fname in sorted(os.listdir(input_dir)):
               if not fname.endswith('.txt'): continue
               for line in open(os.path.join(input_dir, fname)):
                   line = line.strip()
                   if not line or line.startswith('#'): continue
                   exps = re.findall(r'E([+-]?\d+)', line)
                   if exps and all(-24 <= int(e) <= 2 for e in exps):
                       out.write(line + '\n')
   ```
4. Run `swift test --filter Fahmy` to verify

Note: The Fahmy server can be slow. Use generous timeouts with curl.

## Intel Decimal Floating-Point Math Library

**Current version:** v2.0 Update 4
**Source:** https://netlib.org/misc/intel/IntelRDFPMathLib20U4.tar.gz
**License:** BSD 3-Clause (see Intel/LICENSE)

The vendored file is pre-filtered to only bid64 arithmetic operations from
the full `readtest.in` (127K+ lines, 9.4MB). The full file includes bid32,
bid64, and bid128 operations across arithmetic, trigonometry, and conversions.

To update:
1. Download: `curl -O https://netlib.org/misc/intel/IntelRDFPMathLib20U4.tar.gz`
2. Extract the test file: `tar xzf IntelRDFPMathLib20U4.tar.gz TESTS/readtest.in eula.txt`
3. Pre-filter to bid64 arithmetic operations:
   ```bash
   grep -E '^bid64_(add|sub|mul|div|rem|abs|negate|quiet_equal|quiet_less|quiet_greater|minnum|maxnum) ' \
     TESTS/readtest.in > Intel/readtest_bid64.in
   ```
4. Clean up: `rm -rf TESTS/ eula.txt IntelRDFPMathLib20U4.tar.gz`
5. Run `swift test --filter Intel` to verify

## Adding Support for a New Operation

When implementing a new operation (e.g., `sqrt`, `exp`, `fma`):

1. Implement the operation in `Sources/FixedPointDecimal/`
2. In the relevant test file (`GDATests.swift`, `FahmyTests.swift`, or `IntelTests.swift`):
   - Find the `@Test(.disabled(...))` test for that operation
   - Remove the `.disabled(...)` trait
   - Run `swift test --filter <TestName>` to see pass/skip/fail counts
3. Investigate any failures -- they may reveal edge cases in your implementation
4. The test runners automatically skip vectors outside our representable range
   or with precision exceeding 8 fractional digits
