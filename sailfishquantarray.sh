#!/bin/bash

#  sailfishquantarray.sh
#  Sailfish Wrappers
#
#  Created by Richard Gunning on 6/25/14.
#

## Variables
Sailfishdir="/lustre/scratch109/sanger/rg12/Sailfish"
homedir="/nfs/users/nfs_r/rg12"

# When submitted via LSF the following environment variable
# will be set to tell us our array number.
#$LSB_JOBINDEX


line=$(sed -n '$LSB_JOBINDEXp' $homedir/RNAseq_data)
echo $line

# PATH to HMMER
#HMMERPATH=/software/isg/farm-course/hmmer/bin
# PATH to the reference database
#DB=/data/blastdb/Supported/PFAM
# Path to the query fasta files
#QUERY=/software/isg/farm-course/hmmer/data
# Execute hmmer on our query.
# Choose the query by our LSF job index.
#echo $LSB_JOBINDEX
#$HMMERPATH/hmmpfam $DB/Pfam_ls $QUERY/fa.$LSB_JOBINDEX
# $? is a shell variable that is set to the exit code of the
# last command. Exit with this value.
#exit $?