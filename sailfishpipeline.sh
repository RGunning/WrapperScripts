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

while IFS= read -r line; do
file=$(echo $line | cut -f 1 -d " ");
strain=$(echo $line | cut -f 4 -d " " | cut -d '_' -f2);
cell=$(echo $line | cut -f 4 -d " " | cut -d '_' -f1);
gender=$(echo $line | cut -f 4 -d " " | cut -d '_' -f3);

if [ $strain == "CB" ] || [ $strain == "C" ]
then strain2=C
elif [$strain == "BC" ] || [ $strain == "B" ]
then strain2=B
fi

# Check file structure
mkdir $dir/sailfish_index/Quantification/$strain/
mkdir $dir/sailfish_index/Quantification/$strain/$cell
mkdir $dir/sailfish_index/Quantification/$strain/$cell/$gender/$file
mkdir $dir/sailfish_index/Quantification/$strain/$cell/$gender/$file/transcriptome
mkdir $dir/sailfish_index/Quantification/$strain/$cell/$gender/$file/transcriptome_NONCODE/
mkdir $dir/sailfish_index/Quantification/$strain/$cell/$gender/$file/NONCODE/

# make sure output directory is empty
rm $dir/sailfish_index/Quantification/$strain/$cell/$gender/$file/transcriptome/*
rm $dir/sailfish_index/Quantification/$strain/$cell/$gender/$file/transcriptome_NONCODE/*
rm $dir/sailfish_index/Quantification/$strain/$cell/$gender/$file/NONCODE/*



sailfish quant -p 12 -i $dir/sailfish_index/index/$strain2/transcriptome/ -o $dir/sailfish_index/Quantification/$strain/$cell/$gender/$file/transcriptome/ -F <(bamtofastq filename=$dir/$file fasta=0 F2=/dev/null|fastx_trimmer -f 2) -R <(bamtofastq filename=$dir/$file fasta=0  F=/dev/null|fastx_trimmer -f 2)

sailfish quant -p 12 -i $dir/sailfish_index/index/$strain2/transcriptome_NONCODE/ -o $dir/sailfish_index/Quantification/$strain/$cell/$gender/$file/transcriptome_NONCODE/ -F <(bamtofastq filename=$dir/$file fasta=0 F2=/dev/null|fastx_trimmer -f 2) -R <(bamtofastq filename=$dir/$file fasta=0  F=/dev/null|fastx_trimmer -f 2)

sailfish quant -p 12 -i $dir/sailfish_index/index/NONCODE/ -o $dir/sailfish_index/Quantification/$strain/$cell/$gender/$file/NONCODE/ -F <(bamtofastq filename=$dir/$file fasta=0 F2=/dev/null|fastx_trimmer -f 2) -R <(bamtofastq filename=$dir/$file fasta=0  F=/dev/null|fastx_trimmer -f 2)
done < $file
