#!/bin/bash
dir="/lustre/scratch109/sanger/rg12"
threads=12
kmer=20
tgm=false

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
-t	transcript gene map (BOOLEAN)
EOF
}
while getopts “hd:p:k:t” OPTION
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
	t)
	    tgm=true
	    ;;
        ?)
            usage
            exit
            ;;
    esac
done
# Work out the output hash directory
destdir="$dir/Sailfish/output"
outfile="sailfish.$LSB_JOBID"
outdir=$destdir/`echo -n $outfile | md5sum | cut -c1-4 | sed 's:\(..\):\1/:g'`

# Create the directory if it doesn't already exist.  This uses NFS, but
# it's not too painful.  Bomb out if it doesn't work.
mkdir -p "$outdir" || exit 1

# Create some variables with unique temporary filenames.
tmpoutfile=/tmp/$USER.$LSB_JOBID.$LSB_JOBINDEX.$$.tmp
tmperrfile=$tmpoutfile.err
outfile=$outdir/$outfile
errfile=$outfile.err

echo "Sailfish BL6 transcriptome" $tmpoutfile 2>> $tmperrfile;
rm -R $dir/Sailfish/Indexes/B/transcriptome/* $tmpoutfile 2>> $tmperrfile;
if [ "$tgm" = true ]; then
        echo "tgm=true" $tmpoutfile 2>> $tmperrfile;
	sailfish --no-version-check index -t $dir/transcriptomes/C57BL6_transcriptome70.ercc.fa -k $kmer -p $threads -m $dir/Indexes/Mus_musculus.GRCm38.75.gtf -o $dir/Sailfish/Indexes/B/transcriptome/ $tmpoutfile 2>> $tmperrfile;
else
        echo "tgm=false" $tmpoutfile 2>> $tmperrfile;
	sailfish --no-version-check index -t $dir/transcriptomes/C57BL6_transcriptome70.ercc.fa -k $kmer -p $threads -o $dir/Sailfish/Indexes/B/transcriptome/ $tmpoutfile 2>> $tmperrfile;
fi

echo "Sailfish BL6 transcriptome_NONCODE" $tmpoutfile 2>> $tmperrfile;
rm -R $dir/Sailfish/Indexes/B/transcriptome_NONCODE/* $tmpoutfile 2>> $tmperrfile;
sailfish --no-version-check index -t $dir/transcriptomes/C57BL6_transcriptome_NONCODE.fa -k $kmer -p $threads -o $dir/Sailfish/Indexes/B/transcriptome_NONCODE/ $tmpoutfile 2>> $tmperrfile;

echo "Sailfish CAST transcriptome" $tmpoutfile 2>> $tmperrfile;
rm -R $dir/Sailfish/Indexes/C/transcriptome/* $tmpoutfile 2>> $tmperrfile;
if [ "$tgm" = true ]; then
	echo "tgm=true" $tmpoutfile 2>> $tmperrfile;
	sailfish --no-version-check index -t $dir/transcriptomes/CASTEiJ_transcriptome70.ercc.fa -k $kmer -p $threads -m $dir/Indexes/Mus_musculus.GRCm38.75.gtf -o s$dir/Sailfish/Indexes/C/transcriptome/ $tmpoutfile 2>> $tmperrfile;
else
	echo "tgm=false" $tmpoutfile 2>> $tmperrfile;
	sailfish --no-version-check index -t $dir/transcriptomes/CASTEiJ_transcriptome70.ercc.fa -k $kmer -p $threads -o s$dir/Sailfish/Indexes/C/transcriptome/ $tmpoutfile 2>> $tmperrfile;
fi
echo "Sailfish CAST transcriptome_NONCODE" $tmpoutfile 2>> $tmperrfile;
rm -R s$dir/Sailfish/Indexes/C/transcriptome_NONCODE/* $tmpoutfile 2>> $tmperrfile;
sailfish index -t $dir/transcriptomes/CAST_transcriptome_NONCODE.fa -k $kmer -p $threads -o $dir/Sailfish/Indexes/C/transcriptome_NONCODE $tmpoutfile 2>> $tmperrfile;

echo "Sailfish NONCODE" $tmpoutfile 2>> $tmperrfile;
rm -R $dir/Sailfish/Indexes/NONCODE/* $tmpoutfile 2>> $tmperrfile;
sailfish index -t $dir/transcriptomes/Mouse_lncRNA_150.fa -k $kmer -p $threads -o $dir/Sailfish/Indexes/NONCODE/ $tmpoutfile 2>> $tmperrfile;

############


# Store the exit code to be used later as the real exit code of the
# job
status=$?

if [ $status -eq 0 ]; then
	# Job succeeded
	# Copy the output back to the file server, if it has non-zero
	# size
	if [ -s $tmpoutfile ]; then
		cp $tmpoutfile $outfile
	fi
fi

# Copy the errors file, if it's there
if [ -s $tmperrfile ]; then
	cp $tmperrfile $errfile
fi

# Clean up the temporary files
rm -f $tmpoutfile $tmperrfile

# Return the real exit status of the job itself
exit $status
