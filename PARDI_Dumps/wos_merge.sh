# VJ Davey
# This script will be used to create merged csv files for WoS that then are moved to the output directory
# It will additionally copy the delete file
todo_dirs=$1; csv_dir=$2; merge_output=$3; del_csv=$4
prefix=$(date +%F | sed 's/-/_/g')
cat $del_csv > $merge_output/$prefix"_wos"$file"_delete.csv"
files="_abstract _address _author _dois _grant _keyword _publication _reference _title"
for dir in $(cat $todo_dirs); do
  for file in $files; do
    for delta in $(ls $csv_dir/$dir/*$file.csv); do
      cat $delta >> $merge_output/$prefix"_wos"$file"_update.csv"
    done
  done
done
