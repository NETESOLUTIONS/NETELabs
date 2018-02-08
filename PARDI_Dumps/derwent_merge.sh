# VJ Davey
# This script will be used to create merged csv files for Derwent that then are moved to the output directory
csv_dir=$1; merge_output=$2
prefix=$(date +%F | sed 's/-/_/g')
files="_agents _assignees _assignors _patent_citations _examiners _inventors _lit_citations _patents"
for file in $files; do
  for delta in $(ls $csv_dir/*/*$file.csv); do
    cat $delta >> $merge_output/$prefix"_derwent"$file"_update.csv"
  done
done
# rename certain files to adhere to existing standards our users are used to
# TODO: remove this and give our users the original file names after the next quarterly dump
mv $merge_output/$prefix"_derwent_agents_update.csv" $merge_output/$prefix"_derwent_agent_update.csv"
mv $merge_output/$prefix"_derwent_assignees_update.csv" $merge_output/$prefix"_derwent_assignee_update.csv"
mv $merge_output/$prefix"_derwent_assignors_update.csv" $merge_output/$prefix"_derwent_assignor_update.csv"
mv $merge_output/$prefix"_derwent_patent_citations_update.csv" $merge_output/$prefix"_derwent_citation_update.csv"
mv $merge_output/$prefix"_derwent_examiners_update.csv" $merge_output/$prefix"_derwent_examiner_update.csv"
mv $merge_output/$prefix"_derwent_inventors_update.csv" $merge_output/$prefix"_derwent_inventor_update.csv"
mv $merge_output/$prefix"_derwent_lit_citations_update.csv" $merge_output/$prefix"_derwent_litcitation_update.csv"
mv $merge_output/$prefix"_derwent_patents_update.csv" $merge_output/$prefix"_derwent_patent_update.csv"
