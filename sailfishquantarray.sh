#!/bin/bash

#  sailfishquantarray.sh
#  Sailfish Wrappers
#
#  Created by Richard Gunning on 6/25/14.
#
# This is an example LSF job wrapper script with all of the following
# features:

# 1) Handles job arrays
# 2) Places output files into an evenly spread hash directory structure
# 3) Keeps file counts down by only copying output files if they contain
#    any data
# 4) Cleans up temporary files
# 5) Exits with the correct exit code from the real job itself

## Variables
Sailfishdir="/lustre/scratch109/sanger/rg12/Sailfish"
homedir="/nfs/users/nfs_r/rg12"
threads=12
RNAseqlist=$homedir/RNAseq_data

usage()
{
    cat << EOF
usage: $0 options
    
This wrapper script runs sailfish quantification as a LSF job array

OPTIONS:
-h      Show this message
-s      sailfish root directory
-d      homedirectory
-r      File list
-p      threads
EOF
}
while getopts “hs:d:r:p:” OPTION
do
    case $OPTION in
        h)
            usage
            exit 1
            ;;
        s)
            Sailfishdir=$OPTARG
            ;;
        d)
            homedir=$OPTARG
            ;;
        r)
            RNAseqlist=$OPTARG
            ;;
        p)
            threads=$OPTARG
            ;;
        ?)
            usage
            exit
            ;;
    esac
done


# Work out the output hash directory
destdir="$Sailfishdir/output"
outfile="sailfish.$LSB_JOBID.$LSB_JOBINDEX"
outdir=$destdir/`echo -n $outfile | md5sum | cut -c1-4 | sed 's:\(..\):\1/:g'`

# Create the directory if it doesn't already exist.  This uses NFS, but
# it's not too painful.  Bomb out if it doesn't work.
mkdir -p "$outdir" || exit 1

# Create some variables with unique temporary filenames.
tmpoutfile=/tmp/$USER.$LSB_JOBID.$LSB_JOBINDEX.$$.tmp
tmperrfile=$tmpoutfile.err
outfile=$outdir/$file
errfile=$outfile.err

# When submitted via LSF the following environment variable
# will be set to tell us our array number.
#$LSB_JOBINDEX

line=$(sed -n -e ${LSB_JOBINDEX}p $RNAseqlist)

############ Main script

filenameloc=$(echo $line |cut -f 1 -d " " );
file=$(echo $filenameloc | cut -f 6 -d "/");
strain=$(echo $line | cut -f 4 -d " " | cut -d '_' -f2);
cell=$(echo $line | cut -f 4 -d " " | cut -d '_' -f1);
sex=$(echo $line | cut -f 4 -d " " | cut -d '_' -f3);

if [ $strain == "CB" ] || [ $strain == "C" ]
then strain2=C
elif [ $strain == "BC" ] || [ $strain == "B" ]
then strain2=B
fi

# Check file structure
mkdir $Sailfishdir/Quantification/$strain/
mkdir $Sailfishdir/Quantification/$strain/$cell
mkdir $Sailfishdir/Quantification/$strain/$cell/$sex/$file 
mkdir $Sailfishdir/Quantification/$strain/$cell/$sex/$file/transcriptome
mkdir $Sailfishdir/Quantification/$strain/$cell/$sex/$file/transcriptome_NONCODE/ 
mkdir $Sailfishdir/Quantification/$strain/$cell/$sex/$file/NONCODE/

# make sure output directory is empty
rm -R $Sailfishdir/Quantification/$strain/$cell/$sex/$file/transcriptome/* 
rm -R $Sailfishdir/Quantification/$strain/$cell/$sex/$file/transcriptome_NONCODE/* 
rm -R $Sailfishdir/Quantification/$strain/$cell/$sex/$file/NONCODE/* 
# Run 3 sailfish instances
sailfish quant -p $threads -i $Sailfishdir/Indexes/$strain2/transcriptome/ -o $Sailfishdir/Quantification/$strain/$cell/$sex/$file/transcriptome/ -l "T=PE:O=><:S=U" -1 <(bamtofastq filename=$filenameloc fasta=0 F2=/dev/null|fastx_trimmer -f 2) -2 <(bamtofastq filename=$filenameloc fasta=0  F=/dev/null|fastx_trimmer -f 2) > $tmpoutfile 2> $tmperrfile

sailfish quant -p $threads -i $Sailfishdir/Indexes/$strain2/transcriptome_NONCODE/ -o $Sailfishdir/Quantification/$strain/$cell/$sex/$file/transcriptome_NONCODE/ -l "T=PE:O=><:S=U" -1 <(bamtofastq filename=$filenameloc fasta=0 F2=/dev/null|fastx_trimmer -f 2) -2 <(bamtofastq filename=$filenameloc fasta=0  F=/dev/null|fastx_trimmer -f 2) >> $tmpoutfile 2>> $tmperrfile

sailfish quant -p $threads -i $Sailfishdir/Indexes/NONCODE/ -o $Sailfishdir/Quantification/$strain/$cell/$sex/$file/NONCODE/ -l "T=PE:O=><:S=U" -1 <(bamtofastq filename=$filenameloc fasta=0 F2=/dev/null|fastx_trimmer -f 2) -2 <(bamtofastq filename=$filenameloc fasta=0  F=/dev/null|fastx_trimmer -f 2) >> $tmpoutfile 2>> $tmperrfile


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
