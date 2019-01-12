#!/bin/sh
#test03 -legit rm removed files -rm the file which is not in index -force rm or cached rm the file which has been rmed 

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

./legit.pl add 1 2 3 4 5 6 7 8
./legit.pl commit -m 0

rm 1
./legit.pl rm 1
./legit.pl rm 2

echo 33 > 3
echo 44 > 4
./legit add 4

./legit.pl rm 3
./legit.pl rm 4
./legit.pl rm --force 3
./legit.pl rm --force 4

./legit.pl rm --cached 5
./legit.pl rm 5
./legit.pl rm 6
./legit.pl rm --cached 6
./legit.pl rm --cached --force 7
./legit.pl rm --force --cached 8

./legit.pl commit -m 1
./legit.pl show 1:1
./legit.pl show 1:2
./legit.pl show 1:3
./legit.pl show 1:4
./legit.pl show 1:5
./legit.pl show 1:6
./legit.pl show 1:7

