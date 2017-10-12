# VJ Davey
# This script will be used to create merged csv files for Derwent that then are moved to the output directory
csv_dir=$1; merge_output=$2
prefix=$(date +%F | sed 's/-/_/g')
files="_agent _assignee _assignor _citation _examiner _inventor _litcitation _patent"
for file in $files; do
  for delta in $(ls $csv_dir/*/*$file.csv); do
    cat $delta >> $merge_output/$prefix"_derwent"$file"_update.csv"
  done
done
