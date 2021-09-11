#!/bin/sh
rm "${0%/*}/j4fRes.crf"
zip -j "${0%/*}/j4fRes.crf" "${0%/*}/j4fRes/"*
