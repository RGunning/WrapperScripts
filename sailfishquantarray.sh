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

line=$(sed -n -e ${LSB_JOBINDEX}p $homedir/RNAseq_data)

############ Main script

filenameloc=$(echo $line |cut -f 1 -d " " );
file=$(echo $filename | cut -f 6 -d "/");
strain=$(echo $line | cut -f 4 -d " " | cut -d '_' -f2);
cell=$(echo $line | cut -f 4 -d " " | cut -d '_' -f1);
sex=$(echo $line | cut -f 4 -d " " | cut -d '_' -f3);

if [ $strain == "CB" ] || [ $strain == "C" ]
then strain2=C
elif [$strain == "BC" ] || [ $strain == "B" ]
then strain2=B
fi

# Check file structure
mkdir $Sailfishdir/Quantification/$strain/ || exit 1
mkdir $Sailfishdir/Quantification/$strain/$cell || exit 1
mkdir $Sailfishdir/Quantification/$strain/$cell/$sex/$file || exit 1
mkdir $Sailfishdir/Quantification/$strain/$cell/$sex/$file/transcriptome || exit 1
mkdir $Sailfishdir/Quantification/$strain/$cell/$sex/$file/transcriptome_NONCODE/ || exit 1
mkdir $Sailfishdir/Quantification/$strain/$cell/$sex/$file/NONCODE/ || exit 1

# make sure output directory is empty
rm $Sailfishdir/Quantification/$strain/$cell/$sex/$file/transcriptome/* || exit 1
rm $Sailfishdir/Quantification/$strain/$cell/$sex/$file/transcriptome_NONCODE/* || exit 1
rm $Sailfishdir/Quantification/$strain/$cell/$sex/$file/NONCODE/* || exit 1

# Run 3 sailfish instances
sailfish quant -p $threads -i $Sailfishdir/Indexes/$strain2/transcriptome/ -o $Sailfishdir/Quantification/$strain/$cell/$sex/$file/transcriptome/ -l "T=PE:O=><:S=SA" -1 <(bamtofastq filename=$filenameloc fasta=0 F2=/dev/null|fastx_trimmer -f 2) -2 <(bamtofastq filename=$filenameloc fasta=0  F=/dev/null|fastx_trimmer -f 2) > $tmpoutfile 2> $tmperrfile

sailfish quant -p $threads -i $Sailfishdir/Indexes/$strain2/transcriptome_NONCODE/ -o $Sailfishdir/Quantification/$strain/$cell/$sex/$file/transcriptome_NONCODE/ -l "T=PE:O=><:S=SA" -1 <(bamtofastq filename=$filenameloc fasta=0 F2=/dev/null|fastx_trimmer -f 2) -2 <(bamtofastq filename=$filenameloc fasta=0  F=/dev/null|fastx_trimmer -f 2) >> $tmpoutfile 2>> $tmperrfile

sailfish quant -p $threads -i $Sailfishdir/Indexes/NONCODE/ -o $Sailfishdir/Quantification/$strain/$cell/$sex/$file/NONCODE/ -l "T=PE:O=><:S=SA" -1 <(bamtofastq filename=$filenameloc fasta=0 F2=/dev/null|fastx_trimmer -f 2) -2 <(bamtofastq filename=$filenameloc fasta=0  F=/dev/null|fastx_trimmer -f 2) >> $tmpoutfile 2>> $tmperrfile


############
# Run the job, storing the output on the execution host
/usr/local/bin/mow $LSB_JOBINDEX > $tmpoutfile 2> $tmperrfile

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