#!/bin/bash

# Copyright 2021 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e
set -x

cd ffmpeg

if [[ "$RUNNER_OS" == "Linux" ]]; then
  # We only check for static binaries on Alpine Linux.  In other distributions,
  # these are not possible due to the use of glibc.  We allow glibc builds here
  # because while tied to the distro, they at least give us the chance for
  # hardware encoding.
  if ../repo-src/is-alpine.sh; then
    # If ldd succeeds, then these are dynamic executables, so we fail
    # this step if ldd succeeds.  The output of ldd will still be logged.
    ldd ffmpeg && exit 1
    ldd ffprobe && exit 1
  fi
elif [[ "$RUNNER_OS" == "Windows" ]]; then
  # These will still be dynamic executables.
  # Capture the full list of DLL dependencies.
  # With set -x, this also gets logged.
  ffmpeg_deps=$(ldd ffmpeg.exe)
  ffprobe_deps=$(ldd ffprobe.exe)

  # These should not link against anything outside of /c/Windows.  The grep
  # command will succeed if it can find anything outside /c/Windows, and then
  # we fail if that succeeds.
  echo "$ffmpeg_deps" | grep -qvi /c/Windows/ && exit 1
  echo "$ffprobe_deps" | grep -qvi /c/Windows/ && exit 1
elif [[ "$RUNNER_OS" == "macOS" ]]; then
  # These will still be dynamic executables.
  # Capture the full list of dynamic library dependencies.
  # With set -x, this also gets logged.
  ffmpeg_deps=$(otool -L ffmpeg)
  ffprobe_deps=$(otool -L ffprobe)

  # These should not link against anything outside of /usr/lib or
  # /System/Library.  The grep command will succeed if it can find anything
  # outside these two folders, and then we fail if that succeeds.
  echo "$ffmpeg_deps" | grep '\t' | grep -Evq '(/System/Library|/usr/lib)' && exit 1
  echo "$ffprobe_deps" | grep '\t' | grep -Evq '(/System/Library|/usr/lib)' && exit 1
fi

# After commands that we expect to fail (greps and ldd commands
# above), we still need a successful command at the end of the script
# to make this step of the workflow a success.
true
