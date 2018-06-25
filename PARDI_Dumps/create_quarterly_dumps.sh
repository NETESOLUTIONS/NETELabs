#!/usr/bin/env bash
# VJ Davey
# Date 10/11/17

if (( $# < 1 )); then
  cat <<'HEREDOC'
NAME
  create_quarterly_dumps.sh -- create quarterly export of the postgres data

SYNOPSIS
  create_quarterly_dumps.sh export_base_dir
  create_quarterly_dumps.sh: display this help

DESCRIPTION
  Creates Postgres dump and CSV files for CG, CT, FDA, Derwent and WoS modules in ${export_base_dir}/baseline_data/.
  Archives weekly CSV exports for WoS and Derwent modules into ${export_base_dir}/past_quarter_archive/.
  export_base_dir is expected to contain weekly update files in ${export_base_dir}/weekly_updates/.
HEREDOC
  exit 1
fi

set -ex
set -o pipefail

# Get a script directory, same as by $(dirname $0)
#script_dir=${0%/*}
#absolute_script_dir=$(cd "${script_dir}" && pwd)
export_base_dir=$1
#if [[ ! -d "${export_base_dir}" ]]; then
#  mkdir "${export_base_dir}"
#  chmod g+w "${export_base_dir}"
#fi
cd "${export_base_dir}"
echo -e "\n## Running under ${USER}@${HOSTNAME} in ${PWD} ##\n"

echo "### Compiling previous WoS CSVs into a new quarterly archive ###"
cur_qtr=$(python -c "import datetime; import math; print \"%d_Q%d\"%(2018,int(math.ceil(datetime.date.today().month/3.0)))")
# Compile WOS records
wos_weeklies=${export_base_dir}/weekly_updates/WOS
wos_quarter_archive=${export_base_dir}/past_quarter_archive/WOS
rm -f ${wos_quarter_archive}/${cur_qtr}_wos_*_archive.csv
wos_export_tables="abstract address author dois grant keyword publication reference title"
for table in ${wos_export_tables}; do
  echo "Archiving WoS ${table} weekly updates..."
  cat ${wos_weeklies}/*${table}_update.csv >> ${wos_quarter_archive}/${cur_qtr}_wos_${table}_archive.csv
done
#rm ${wos_weeklies}/*

echo "### Compiling previous Derwent CSVs into a new quarterly archive ###"
derwent_weeklies=${export_base_dir}/weekly_updates/DERWENT
derwent_quarter_archive=${export_base_dir}/past_quarter_archive/DERWENT
rm -f ${derwent_quarter_archive}/${cur_qtr}_derwent_*_archive.csv
derwent_export_tables="agent assignee citation examiner inventor litcitation patent"
for table in ${derwent_export_tables}; do
  echo "Archiving Derwent ${table} weekly updates..."
  cat ${derwent_weeklies}/*${table}_update.csv >> ${derwent_quarter_archive}/${cur_qtr}_derwent_${table}_archive.csv
done
#rm ${derwent_weeklies}/*

## CREATE NEW DUMP FILES
# Take in user input for output directory for files
baseline_dump_dir=${export_base_dir}/baseline_data

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
  pg_dump --section=pre-data --section=data --no-owner --no-privileges --no-tablespaces -t ${prefix}_* \
          $exclude_string | gzip > ${baseline_dump_dir}/${prefix}_dump.sql.gz
#  while [ "$(ps $! | grep $!)" ]; do
#    sleep 15; echo "still working to generate ${prefix} sql dump script ..."
#  done
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

chmod -R g+w,o+r ${export_base_dir}