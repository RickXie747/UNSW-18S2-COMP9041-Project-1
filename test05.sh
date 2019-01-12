#!/bin/sh
#test06 -branch  master->commit->branch b1->new file->checkout b1->new file and change file->only add new file->commit
#	        master->commit->branch b1->new file->checkout b1->new file and change file->only add changed file->commit

rm -r .legit

./legit.pl init

echo 1 > 1
./legit.pl add 1
./legit.pl commit -m 0
./legit.pl branch b1
echo 2 >> 1
./legit.pl commit -a -m 1
./legit.pl checkout b1
ls
cat 1
echo 3 >> 1
echo a > a
./legit.pl add a
./legit.pl commit -a -m 2
./legit.pl checkout master
ls
cat 1
./legit.pl checkout b1
ls
cat 1


rm -r .legit
rm 1 a

./legit.pl init

echo 1 > 1
./legit.pl add 1
./legit.pl commit -m 0
./legit.pl branch b1
echo 2 >> 1
./legit.pl commit -a -m 1
./legit.pl checkout b1
ls
cat 1
echo 3 >> 1
echo a > a
./legit.pl add 1
./legit.pl commit -a -m 1
./legit.pl checkout master
ls
cat 1
./legit.pl checkout b1
ls
cat 1

