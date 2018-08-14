#!/usr/bin/env bash
# VJ Davey
if [[ $1 == "-h" ]]; then
  cat <<'HEREDOC'
NAME
  generate_wos_weeklies.sh -- generate weekly WOS csv data.

SYNOPSIS
  generate_wos_weeklies.sh "{date_string}" target_dir work_dir  -- where date_string is some string in the format YYYY-MM-DD
  generate_wos_weeklies.sh -h: display this help

DESCRIPTION
  Generates weekly WOS csv data
HEREDOC
  exit 1
fi

set -ex
set -o pipefail

# Get a script directory, same as by $(dirname $0)
script_dir=${0%/*}
#absolute_script_dir=$(cd "${script_dir}" && pwd)
#work_dir=${1:-${absolute_script_dir}/build} # $1 with the default
#if [[ ! -d "${work_dir}" ]]; then
#  mkdir "${work_dir}"
#  chmod g+w "${work_dir}"
#fi
#cd "${work_dir}"
echo -e "\n## Running under ${USER}@${HOSTNAME} in ${PWD} ##\n"

# Set aside the most recent wos ids that have yet to be shared
date_string=$1; target_dir=$2; work_dir=$3
prefix=$(date +%F | sed 's/-/_/g')
echo "building files after date ${date_string}"
psql -c "DROP TABLE IF EXISTS temp_weekly_wos_ids;"
psql -c "SELECT source_id INTO temp_weekly_wos_ids FROM wos_publications WHERE last_modified_date > '${date_string}';"

# Pull the data from each wos_table with the ids in question
psql -c "COPY (SELECT id,a.source_id,abstract_text,source_filename\
      FROM wos_abstracts a INNER JOIN temp_weekly_wos_ids b on a.source_id=b.source_id)\
      TO STDOUT CSV HEADER;" > ${target_dir}/${prefix}_wos_abstract_update.csv

psql -c "COPY (SELECT id,a.source_id,address_name,organization,sub_organization,city,\
      country,zip_code,source_filename\
      FROM wos_addresses a INNER JOIN temp_weekly_wos_ids b on a.source_id=b.source_id)\
      TO STDOUT CSV HEADER;" > ${target_dir}/${prefix}_wos_address_update.csv

psql -c "COPY (SELECT id,a.source_id,full_name,last_name,first_name,seq_no,address_seq,\
      address,email_address,address_id,dais_id,r_id,source_filename\
      FROM wos_authors a INNER JOIN temp_weekly_wos_ids b on a.source_id=b.source_id)\
      TO STDOUT CSV HEADER;" > ${target_dir}/${prefix}_wos_author_update.csv

psql -c "COPY (SELECT id,a.source_id,document_id,document_id_type,source_filename\
      FROM wos_document_identifiers a INNER JOIN temp_weekly_wos_ids b on a.source_id=b.source_id)\
      TO STDOUT CSV HEADER;" > ${target_dir}/${prefix}_wos_dois_update.csv

psql -c "COPY (SELECT id,a.source_id,grant_number,grant_organization,funding_ack,source_filename\
      FROM wos_grants a INNER JOIN temp_weekly_wos_ids b on a.source_id=b.source_id)\
      TO STDOUT CSV HEADER;" > ${target_dir}/${prefix}_wos_grant_update.csv

psql -c "COPY (SELECT id,a.source_id,keyword,source_filename\
      FROM wos_keywords a INNER JOIN temp_weekly_wos_ids b on a.source_id=b.source_id)\
      TO STDOUT CSV HEADER;" > ${target_dir}/${prefix}_wos_keyword_update.csv

psql -c "COPY (SELECT begin_page,created_date,document_title,document_type,edition,end_page,end_page,\
      has_abstract,id,issue,language,last_modified_date,publication_date,publication_year,\
      publisher_address,publisher_name,source_filename,a.source_id,source_title,source_type,volume\
      FROM wos_publications a INNER JOIN temp_weekly_wos_ids b on a.source_id=b.source_id)\
      TO STDOUT CSV HEADER;" > ${target_dir}/${prefix}_wos_publication_update.csv

psql -c "COPY (SELECT wos_reference_id,a.source_id,cited_source_uid,cited_title,cited_work,cited_author,\
      cited_year,cited_page,created_date,last_modified_date,source_filename\
      FROM wos_references a INNER JOIN temp_weekly_wos_ids b on a.source_id=b.source_id)\
      TO STDOUT CSV HEADER;" > ${target_dir}/${prefix}_wos_reference_update.csv

psql -c "COPY (SELECT id,a.source_id,title,type,source_filename\
      FROM wos_titles a INNER JOIN temp_weekly_wos_ids b on a.source_id=b.source_id)\
      TO STDOUT CSV HEADER;" > ${target_dir}/${prefix}_wos_title_update.csv

# Round up delete files
echo "del_source_id" > ${target_dir}/${prefix}_wos_delete.csv
# Concatenate WOS ids from all delete files
if compgen -G "${work_dir}/*.del" >/dev/null; then
  for i in ${work_dir}/*.del; do
    awk -F ',' '{print $1":"$2}' ${i} >> ${target_dir}/${prefix}_wos_delete.csv
  done
fi

echo "Weekly WOS CSV files built."

# Set permissions on generated files
chmod 775 ${target_dir}/*
