#!/bin/sh
#test05 -branches master->b1 new file>b11 new file master->b2 add file->b3 change file 

rm -r .legit

./legit.pl init

echo 1 > 1

./legit.pl add 1  
./legit.pl commit -m 0

./legit.pl branch master
./legit.pl branch b1
./legit.pl branch b1
echo 2 > 2
./legit.pl add 2
./legit.pl commit -m 1

./legit.pl branch b11
echo 3 > 3
./legit.pl add 3
./legit.pl commit -m 2

./legit.pl checkout master
./legit.pl branch b2
echo 4 > 4
./legit.pl add 4
./legit.pl commit -m 3

./legit.pl branch b21
echo 444 > 4
./legit.pl add 4
./legit.pl commit -m 4

./legit.pl checkout master
ls
./legit.pl checkout b1
ls
./legit.pl checkout b11
ls
./legit.pl checkout b2
ls
cat 4
./legit.pl checkout b21
ls
cat 4
