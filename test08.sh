#!/bin/sh
#test09 -merge brach has the same name with commit: a number 

rm -r .legit

./legit.pl init

seq 1 5 > 1
./legit.pl add 1 
./legit.pl commit -m 0

./legit.pl branch 0
./legit.pl checkout 0
seq 2 6 > 1
./legit.pl commit -m 1

./legit.pl checkout master
./legit.pl merge 0 commit -m m1
cat 1


