#!/bin/sh
#test01 -add incorrect filenames -incorrect commit usage -show non-exist commits and files

rm -r .legit

./legit.pl init
./legit.pl init

touch 1 1. 1_ 1+ _1
echo 0 > 1
echo 00 > 1_

./legit.pl add 1 
./legit.pl add 1.
./legit.pl add 1_ 999
./legit.pl add 1+
./legit.pl add _1 

./legit.pl commit 
./legit.pl -m
./legit.pl hello 
./legit.pl hello commit -m
./legit.pl commit -m hello world
./legit.pl commit -m "hello world"

echo 1 > 1
echo 2 > 2
./legit.pl add 1
./legit.pl add 2
./legit.pl commit -m "hello world 2"

./legit.pl show 0:_1
./legit.pl show 0:1
./legit.pl show 1:_1
./legit.pl show 1:1
./legit.pl show 1:2
./legit.pl show 1:999
./legit.pl show 2:1
./legit.pl show 2:999
./legit.pl show :2
./legit.pl show :999








