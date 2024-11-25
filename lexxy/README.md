# Lexxy

Lisp, but in Hex.

Reference: https://norvig.com/lispy.html

## Types

- Symbols are represented by patterns.
- Lists are lists.
- Everything else is treated as a constant, ie. evaluating it returns itself.
  - Number patterns are evaluated while parsing, so all number patterns are replaced with number iotas before evaluation starts.
