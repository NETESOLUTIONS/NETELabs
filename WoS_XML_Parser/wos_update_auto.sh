#!/bin/sh
# This script updates the Web of Science (WOS) tables in an ETL process.
# Authors Shixin Jiang and Lingtian 'Lindsay' Wan.
# circa June 2016
# Specifically:
# 1. Get files (WOS_CORE and .del) downloaded but not updated yet;
# 2. Unzip .del files and combine WOS ids in these files to a single file;
# 3. Unzip WOS_CORE files to get XML files;
# 4. Split XML files to smaller files, so that Python parser can handle;
# 5. For each small file, parse to CSV and load CSV to database new tables:
#    new_wos_*;
# 6. Update the main WOS tables (wos_*) with records in new tables (new_wos_*);
# 7. Delete records from the main WOS tables (wos_*) with WOS id in .del files;
# 8. Update log file.

# Usage: sh wos_update_auto.sh work_dir/
#   where work_dir specifies working directory.

# Author: Lingtian "Lindsay" Wan
# Create Date: 02/24/2016
# Modified: 05/17/2016
#           06/07/2016, Lindsay Wan, divided wos_references update to loops of small chunks
#           11/17/2016, Lindsay Wan, added command to prepare a file list of parsed csv directories for production server
#           11/28/2016, Lindsay Wan, added list del wos files to a txt for prod server.

# Change to working directory
c_dir=$1
cd $c_dir

# Remove previous timestamp and stamp the current time.
rm starttime.txt
rm endtime.txt
date
date > starttime.txt

# Remove previous files.
rm complete_filelist.txt
rm todo_filelist.txt
rm split_all_xml_files.sh
rm load_wos_update.sh
rm cp_file.sh
rm del_wosid.csv
rm unzip_all.sh
rm ./xml_files_splitted/*.xml

# Copy from ./update_files/ to current directory the WOS_CORE and .del files
# that have not been updated.
echo ***Comparing file list...
ls update_files > complete_filelist.txt
sed -i '/ESCI/d' complete_filelist.txt # delete lines with ESCI files
grep -Fxvf finished_filelist.txt complete_filelist.txt > todo_filelist.txt
cat todo_filelist.txt | awk -v store_dir=$c_dir '{print "cp " store_dir "update_files/" $1 " ."}' > cp_file.sh
sh cp_file.sh

# Get WOS IDs from .del files.
echo ***Extracting WOS IDs from .del files...
# Unzip delete files.
gunzip WOS*.del.gz
# Save delete WOS IDs to a delete records file.
cat WOS*.del | awk '{split($1,filename,",");print "WOS:" filename[2]}' > del_wosid.csv

# Update WOS_CORE files one by one, in time sequence.
for file in $(ls *.tar.gz | sort -n)
do
  # Unzip update file to a sub-directory.
  echo ***Unzipping update file: $file
  tar -zxvf $file *.xml*
  gunzip ${file%%.*}/*
  # Split update xml file to small pieces and move to ./xml_files_splitted/.
  echo ***Splitting update file: $file
  find ./${file%%.*} -name '*.xml' | sort | awk '{print "echo Splitting " $1 "\n" "/anaconda2/bin/python new_xml_split.py " $1 " REC 20000"}' > split_all_xml_files.sh
  sh split_all_xml_files.sh
  find ./${file%%.*} -name '*SPLIT*' -print0 | xargs -0 mv -t ./xml_files_splitted
  # Write update file loading commands to a script.
  echo ***Preparing load update file: $file
  ls xml_files_splitted | grep .xml | awk -v store_dir=$c_dir ' {split($1,filename,".");print "echo Parsing " $1 "\n" "/anaconda2/bin/python wos_xml_update_parser.py -filename " $1 " -csv_dir " store_dir "xml_files_splitted/\n" "echo Loading " $1 "\n" "psql pardi < " store_dir "xml_files_splitted/" filename[1] "/" filename[1] "_load.pg" }' > load_wos_update.sh
  # Parse and load update file to the database.
  echo ***Parsing and loading update file to database: $file
  sh load_wos_update.sh
  # Update the WOS tables.
  echo ***Updating WOS tables
  # Update wos tables other than wos_referneces.
  psql -d pardi -f wos_update_tables.sql
  # Update wos_reference table.
  /anaconda2/bin/python wos_update_split_db_table.py -tablename new_wos_references -rowcount 10000 -csv_dir $c_dir/table_split/
  psql -d pardi -f ./table_split/load_csv_table.sql
  for table_chunk in $(cat ./table_split/split_tablename.txt)
  do
    echo $table_chunk
    psql -d pardi -f wos_update_ref_tables.sql -v new_ref_chunk=$table_chunk
  done
  psql -d pardi -c 'truncate table new_wos_references;'
  psql -d pardi -c 'update update_log_wos set last_updated = current_timestamp where id = (select max(id) from update_log_wos);'
  rm -f table_split/*.csv
  rm xml_files_splitted/*.xml
  rm table_split/load_csv_table.sql
  rm table_split/split_tablename.txt
  printf $file'\n' >> finished_filelist.txt
done

# Delete table records with delete wos_ids.
psql -d pardi -f wos_delete_tables.sql -v delete_csv="'"$c_dir"del_wosid.csv'"
ls WOS*.del | awk '{print $1 ".gz"}' >> finished_filelist.txt

# Delete update and .del files.
rm *.del
rm -rf WOS*CORE
rm -rf WOS*ESCI
rm WOS*tar.gz

# Prepare csv directory list for Production server.
ls ./xml_files_splitted/ | grep WOS_RAW > parsed_csv_dir.txt
ls ./update_files/ | grep del.gz > del_wosid_filelist.txt

# Stamp the time.
date > endtime.txt
date

# Send log via email.
psql -d pardi -c 'select * from update_log_wos;' | mail -s "WOS Weekly Update Log" username@nete.com

printf "\n\n"
