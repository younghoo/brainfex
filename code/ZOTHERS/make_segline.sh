#! /bin/bash

## Author: Yang Hu / free_learner@163.com

## This script makes a line of characters to segment text into blocks

## Function to make the segment line
make_segline() {
    echo $(printf '%.s'$1 $(seq 1 $2))
}

## Make the line
CHAR='-'
NC=50
make_segline $CHAR $NC

