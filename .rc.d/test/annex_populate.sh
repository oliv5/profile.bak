#!/bin/sh

. ~/.rc

MYPATH="$PWD"
chmod 777 -R repo/ && rm repo/ -rf
chmod 777 -R special/ && rm special/ -rf
chmod 777 -R output/ && rm output/ -rf
mkdir -p repo
mkdir -p special
mkdir -p output

cd repo
git init .
git annex init repo
echo a > a
echo b > b
mkdir c
echo d > c/d
mkdir f
echo g > f/g
echo h > f/h
echo i > f/i
git annex add .
git annex sync

git annex initremote test type=directory directory="$MYPATH/special" encryption=none
git annex copy . --to test

git annex find --format='${hashdirmixed}  ${hashdirlower}   ${key}   ${backend}\n'

echo e > c/e
git annex add .
git annex sync

git annex whereis c/d
git annex whereis c/e

DST="$MYPATH/special/$(git annex find c/e --format='${hashdirlower}${key}/${key}')"
mkdir -p "$(dirname "$DST")"

[ ! -e "$DST" ] && cp c/e "$DST"
ls -l "$DST"

git annex whereis c/e
git annex fsck c/e --from=test --fast
git annex whereis c/e

git annex list

find -not -path "*/.git*"
(set -vx; WHERE="c/ --in . --or --not --in ." annex_populate "$MYPATH/output")
find "$MYPATH/output"

git annex initremote output type=directory directory="$MYPATH/output" encryption=none
git annex fsck . --from=output --fast

git annex whereis c/e
git annex list

git annex drop c/e
git annex whereis c/e

git annex get c/e --from output
git annex whereis c/e
git annex whereis f/g

echo "Remove f/g"
rm f/g
git annex whereis f/g

(set -vx; WHERE="f/ --in . --or --not --in ." annex_populated "$MYPATH/output")

git annex whereis c/e
git annex whereis f/g

git annex fsck . --fast
git annex whereis f/g
git annex list

git annex fsck . --from=output --fast
git annex whereis f/g
git annex list

find "$MYPATH/output"

cd "$MYPATH"
chmod 777 -R repo/ && rm repo/ -rf
chmod 777 -R special/ && rm special/ -rf
chmod 777 -R output/ && rm output/ -rf
