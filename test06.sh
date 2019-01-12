#!/bin/sh
#test07 -merge files more lines or less lines or conflicts -merge one branch and then merge another branch 

rm -r .legit

./legit.pl init

seq 1 3 > 1
echo 1 > 2
./legit.pl add 1 2
./legit.pl commit -m 0

./legit.pl branch b1
./legit.pl checkout b1
seq 2 4 > 1
echo 2 >> 2
./legit.pl commit -a -m 1

./legit.pl branch b2
./legit.pl checkout b2
seq 0 3  > 1
echo 333  >> 2
./legit.pl commit -a -m 2

./legit.pl checkout master
./legit.pl merge b1 commit -m m1
cat 1
cat 2

./legit.pl checkout master
./legit.pl merge b2 commit -m m1
cat 1
cat 2

