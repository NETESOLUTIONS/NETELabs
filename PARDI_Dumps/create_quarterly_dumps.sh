# VJ Davey
# This script is used to create quarterly dumps of the postgres data for our end users
# Usage:
#       sh create_quarterly_dumps.sh baseline_dump_dir
# where $baseline_dump_dir specifies the directory we want all the dump files to go to
# Date 10/11/17

# Record start time
echo "STARTED: $(date)"

#output_dir
output_dir=$1

## COMPILE PREVIOUS CSVs INTO A NEW QUARTERLY ARCHIVE
cur_qtr=$(python -c "import datetime; import math; print \"%d_Q%d_\"%(2018,int(math.ceil(datetime.date.today().month/3.0)))")
# Compile WOS records
wos_weeklies=${output_dir}/weekly_updates/WOS
wos_quarter_archive=${output_dir}/past_quarter_archive/WOS
files="abstract address author dois grant keyword publication reference title"
for file in $files; do
  cat ${wos_weeklies}/*${file}_update.csv >> ${wos_quarter_archive}/${cur_qtr}_wos_${file}_archive.csv
done
#rm ${wos_weeklies}/*

# Compile Derwent files
derwent_weeklies=${output_dir}/weekly_updates/DERWENT
derwent_quarter_archive=${output_dir}/past_quarter_archive/DERWENT
files="agents assignees assignors pat_citations examiners inventors lit_citations patents"
for file in $files; do
  cat ${derwent_weeklies}/*${file}_update.csv >> ${derwent_quarter_archive}/${cur_qtr}_derwent_${file}_archive.csv
done
#rm ${derwent_weeklies}/*

## CREATE NEW DUMP FILES
# Take in user input for output directory for files
baseline_dump_dir=${output_dir}/baseline_data

# Manually build and maintain a list of exclusion tables for the quarterly dump process. These are the tables with matching prefixes for the main data sources that we do not want pushed to the client.
exclude_tables="cg_gen1_ref cg_gen1_ref_grant cg_gen1_ref_pmid cg_gen2_ref cg_gen2_ref_grant cg_gen2_ref_pmid cg_pmid_wos cg_ref_counts_id_seq cg_ref_counts cg_pmid_wos cg_onkens_inventory derwent_familyid derwent_patents_filterred_to_nih_support fda_drug_patents fda_purple_cber_book fda_purple_cder_book"
exclude_string=""

# Build the exclusion string (this sets exclusion options for the given tables and their sequences on the pg_dump command).
for table in $exclude_tables ; do
        exclude_string="${exclude_string} -T ${table} -T ${table}*_seq "
done

# Build the different dump files
data_sources="cg ct fda derwent wos"
for prefix in $data_sources; do

  # Generate pg_dump file
  pg_dump pardi --section=pre-data --section=data --no-owner --no-privileges --no-tablespaces -t ${prefix}_* $exclude_string | gzip > ${baseline_dump_dir}/${prefix}_dump.sql.gz &
  while [ "$(ps $! | grep $!)" ]; do
    sleep 15; echo "still working to generate ${prefix} sql dump script ..."
  done
  echo "FILE ${baseline_dump_dir}/${prefix}_dump.sql CREATED AND COMPRESSED: $(date)"

  # Generate CSV dump files
  psql -c "DROP TABLE IF EXISTS temp_block_tables; CREATE TABLE temp_block_tables (table_name text)"
  for table in $exclude_tables ; do psql -c "INSERT INTO temp_block_tables VALUES ('${table}')" ; done
  rm -rf ${baseline_dump_dir}/${prefix}_csv_dump ; mkdir ${baseline_dump_dir}/${prefix}_csv_dump
  psql -c "COPY (SELECT table_name FROM information_schema.tables t WHERE table_type='BASE TABLE' and table_name like '${prefix}%' and table_name not in (select * from temp_block_tables)) TO STDOUT" | $(while read -r line; do psql -c "COPY ${line} TO STDOUT" | gzip > ${baseline_dump_dir}/${prefix}_csv_dump/${line}.csv.gz ; done) &
  while [ "$(ps $! | grep $!)" ]; do
    sleep 15; echo "still working to generate ${prefix} csv dump script ..."
  done
  tar -zcvf ${baseline_dump_dir}/${prefix}_csv_dump.tar.gz ${baseline_dump_dir}/${prefix}_csv_dump
  rm -rf ${baseline_dump_dir}/${prefix}_csv_dump
  echo "FILE ${baseline_dump_dir}/${prefix}_csv_dump.sql CREATED AND COMPRESSED: $(date)"
done

# Record end time
echo "FINISHED: $(date)"
