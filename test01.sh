#!/bin/sh
#test02 -remove the file and add it -edit the file and add and commit it -add new file and commit it

rm -r .legit

./legit.pl init

echo 1 > 1
echo 2 > 2

./legit.pl add 1
./legit.pl commit -m 0

rm 1
./legit.pl add 1
./legit.pl commit -m 1

./legit.pl add 2
./legit.pl commit -m 2

echo 3 > 2
./legit.pl commit -m 3
./legit.pl add 2
./legit.pl commit -m 3

echo a > a
./legit.pl add a
echo 4 > 2
./legit.pl commit -a -m 4

./legit.pl show 0:1
./legit.pl show 1:1
./legit.pl show 2:1
./legit.pl show 2:2
./legit.pl show 3:2
./legit.pl show 4:a
./legit.pl show 4:2
./legit.pl log

