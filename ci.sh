#!/bin/bash

set -euo pipefail

dub test
cd example || exit 1
dub build
