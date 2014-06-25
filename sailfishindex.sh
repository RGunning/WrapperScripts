#!/bin/bash
dir="/lustre/scratch109/sanger/rg12"
threads=12
kmer=20

usage()
{
cat << EOF
usage: $0 options

This script sets up a file directry tree for Sailfish based on a infile

OPTIONS:
-h      Show this message
-d      directory
-p      threads
-k      kmersize
EOF
}
while getopts “hd:p:k:” OPTION
do
    case $OPTION in
        h)
            usage
            exit 1
            ;;
        d)
            dir=$OPTARG
            ;;
        p)
            threads=$OPTARG
            ;;
        k)
            kmer=$OPTARG
            ;;
        ?)
            usage
            exit
            ;;
    esac
done


rm -R $dir/Sailfish/Indexes/B/transcriptome/*;
sailfish index -t $dir/transcriptomes/C57BL6_transcriptome70.ercc.fa -k $kmer -p $threads -m $dir/transcriptomes/transcript_gene.tgm -o $dir/Sailfish/Indexes/B/transcriptome/ ;
rm -R $dir/Sailfish/Indexes/B/transcriptome_NONCODE/*;
sailfish index -t $dir/transcriptomes/C57BL6_transcriptome_NONCODE.fa -k $kmer -p $threads -m $dir/transcriptomes/transcript_gene.tgm -o $dir/Sailfish/Indexes/B/transcriptome_NONCODE/ ;

rm -R $dir/Sailfish/Indexes/C/transcriptome/*;
sailfish index -t $dir/transcriptomes/CASTEiJ_transcriptome70.ercc.fa -k $kmer -p $threads -m $dir/transcriptomes/transcript_gene.tgm -o s$dir/Sailfish/Indexes/C/transcriptome/ ;
rm -R s$dir/Sailfish/Indexes/C/transcriptome_NONCODE/*;
sailfish index -t $dir/transcriptomes/CAST_transcriptome_NONCODE.fa -k $kmer -p $threads -m $dir/transcriptomes/transcript_gene.tgm -o $dir/Sailfish/Indexes/C/transcriptome_NONCODE ;

rm -R $dir/Sailfish/Indexes/NONCODE/*;
sailfish index -t $dir/transcriptomes/Mouse_lncRNA_150.fa -k $kmer -p $threads -m $dir/transcriptomes/transcript_gene.tgm -o $dir/Sailfish/Indexes/NONCODE/ ;
