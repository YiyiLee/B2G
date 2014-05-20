#!/bin/bash

for FILE in $(find libs -type f); do
    sed -ni '1h;1!H;${g;s/\(ALOG[A-Z]\?([^;\n]*;\n\)/((void)0);\n#if 0\n\1#endif\n/g;s/\(define[^a-zA-Z_]*\)\([a-zA-Z_]*\)[^\n]*ALOG[A-Z][^\n]*\n/\1\2(...) ((void)0)\n/g;p}' "$FILE"
done
