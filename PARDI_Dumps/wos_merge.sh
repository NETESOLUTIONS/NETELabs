# VJ Davey
# This script will be used to create merged csv files for WoS that then are moved to the output directory
# It will additionally copy the delete file
csv_dir=$1; merge_output=$2; del_csv=$3
prefix=$(date +%F | sed 's/-/_/g')
cat $del_csv > $merge_output/$prefix"_wos_delete.csv"
files="_abstract _address _author _dois _grant _keyword _publication _reference _title"
for file in $files; do
  for delta in $(ls $csv_dir/*/*$file.csv); do
    cat $delta >> $merge_output/$prefix"_wos"$file"_update.csv"
  done
done
