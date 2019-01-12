#!/bin/sh
#test07 -more branches and file edited or removed, some are added and committed, check log and files in different branch

rm -r .legit

./legit.pl init

echo 1 > 1
echo 2 > 2
echo 3 > 3
echo 4 > 4
echo 5 > 5
echo 6 > 6

./legit.pl add 1 2
echo 11 > 1
./legit.pl commit -m 0

./legit.pl branch b1
echo 22 > 2
./legit.pl checkout b1
./legit.pl add 3 4 
echo 33 > 3
./legit.pl commit -m 1

./legit.pl branch b2
./legit.pl add 6
./legit.pl rm 4
echo 55 > 5
./legit.pl commit -m 2

./legit.pl checkout master
ls
cat 1 2 3 4 5 6 
./legit.pl checkout b1
ls
cat 1 2 3 4 5 6 
./legit.pl checkout b2
ls 
cat 1 2 3 4 5 6
