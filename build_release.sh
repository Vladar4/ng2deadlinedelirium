#!/bin/sh
cd src
nim c --multimethods:on -d:release --opt:speed --out:../deadlinedelirium main.nim
cd ..

