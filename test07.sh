#!/bin/sh
#test08 -put new files and change files, add all of them or not add any of them, add new branches and checkout, check status

rm -r .legit

./legit.pl init

echo 1 > 1
echo 2 > 2
./legit.pl add 1 2
./legit.pl commit -m 0
echo 3 > 3
./legit.pl branch b1
echo 4 > 4

./legit.pl checkout b1
echo 11 > 1
echo a > a
./legit.pl commit -m 1

./legit.pl checkout master
echo 33 > 3
echo 22 > 2
./legit.pl add 2
rm 4
./legit.pl status
./legit.pl log

./legit.pl checkout b1
./legit.pl status
./legit.pl log

