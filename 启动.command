#!/bin/bash
set -euo pipefail
project_dir="$(cd "$(dirname "$0")" && pwd)"
if [ ! -d "$project_dir/dist/Quiet Line.app" ]; then
    /bin/bash "$project_dir/scripts/build.sh"
fi
open "$project_dir/dist/Quiet Line.app"
