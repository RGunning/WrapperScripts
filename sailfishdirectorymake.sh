#!/bin/bash
dir="/lustre/scratch109/sanger/rg12/Sailfish"

usage()
{
cat << EOF
usage: $0 options

This script sets up a file directry tree for Sailfish based on a infile

OPTIONS:
-h      Show this message
-f      infile
-d      directory
EOF
}
while getopts “hf:d:” OPTION
do
case $OPTION in
    h)
        usage
        exit 1
        ;;
    f)
        file=$OPTARG
        ;;
    d)
        dir=$OPTARG
        ;;
    ?)
        usage
        exit
        ;;
esac
done

if [[ -z $file ]]
    then
        usage
        exit 1
fi


while IFS= read -r line;
do file=$(echo $line |cut -f 1 -d " " | cut -f 6 -d "/");
strain=$(echo $line | cut -f 4 -d " " | cut -d '_' -f2);
cell=$(echo $line | cut -f 4 -d " " | cut -d '_' -f1);
gender=$(echo $line | cut -f 4 -d " " | cut -d '_' -f3);

mkdir $dir/Quantification
mkdir $dir/Quantification/$strain
mkdir $dir/Quantification/$strain/$cell
mkdir $dir/Quantification/$strain/$cell/$gender
mkdir $dir/Quantification/$strain/$cell/$gender/$file
mkdir $dir/Quantification/$strain/$cell/$gender/$file/transcriptome
mkdir $dir/Quantification/$strain/$cell/$gender/$file/transcriptome_NONCODE
mkdir $dir/Quantification/$strain/$cell/$gender/$file/NONCODE

done < $file
