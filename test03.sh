#!/bin/sh
#test04 -status of differnet files

rm -r .legit

./legit.pl init

echo 1 > 1
echo 2 > 2
echo 3 > 3
echo 4 > 4
echo 5 > 5
echo 6 > 6
echo 7 > 7
echo 8 > 8
echo 9 > 9

./legit.pl add 1 2 3 4 5 6 7 
./legit.pl commit -m 0

rm 1
./legit.pl rm 2
./legit.pl rm --cached 3

echo 44 > 4
echo 55 > 5
echo 66 > 6
./legit.pl add 4 6
echo 666 > 6

./legit.pl status

rm 9
./legit.pl commit -m 1
./legit.pl status

