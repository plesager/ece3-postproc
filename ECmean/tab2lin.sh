#!/bin/bash

function getcell {
f=$1
row=$(( $2 + 3  ))
sed -n "${row},${row}p" $f | cut -f 3
}
function getcell2 {
f=$1
row=$(( $2 + 26  ))
sed -n "${row},${row}p" $f | cut -f 3
}

exp=$1
y1=$2
y2=$3
echo -n "${exp}(${y1}-${y2}) | "
f=$exp/Global_Mean_Table_${exp}_${y1}_${y2}.txt

for row in 1 2 3 4 5 6 7 8 9 11 13
do
echo -n $(getcell $f $row ) "| "
done

for row in 1 3 4 5 6 7 11
do
echo -n $(getcell2 $f $row ) "| "
done
echo


