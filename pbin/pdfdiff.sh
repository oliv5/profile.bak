#!/bin/bash
# First argument is the revision reference
# Second argument is the path to the document

BASE_DIR=$(dirname $0)/..
LATEXDIFF=$BASE_DIR/pkg/latexdiff
LD_CFG=$(dirname $0)/ld.cfg

OLD_FILE=$BASE_DIR/obj/oldRev.tex
TMP_FILE=$BASE_DIR

git show $1:$2 > $OLD_FILE

SHORT_SRC=$(basename $2)
SHORT_SRC=${SHORT_SRC:0:5}

#Remove code section before doing the diff
TMP_OLD=$BASE_DIR/obj/oldTmp.tex
TMP_NEW=$BASE_DIR/obj/newTmp.tex

REPLACE_CODE='\\begin{center}{\\color{red}{\\large Code snippet not shown in diff file}}\\end{center}'
awk -f $BASE_DIR/build/stripCode.awk REPLACE="$REPLACE_CODE" $OLD_FILE > $TMP_OLD
awk -f $BASE_DIR/build/stripCode.awk REPLACE="$REPLACE_CODE" $2 > $TMP_NEW

echo "Generating diff for $2 based on release $1 ..."

$LATEXDIFF -c $LD_CFG --packages=hyperref  $TMP_OLD  $TMP_NEW > $BASE_DIR/src/diff_${SHORT_SRC}_$1.tex

echo "Diff file is $BASE_DIR/src/diff_${SHORT_SRC}_$1.tex"
