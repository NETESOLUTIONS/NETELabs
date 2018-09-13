#!/usr/bin/env bash

# Author: Akshat Maltare
# * Running N instances of parser in parallel
# **

if [[ $1 == "-h" ]]; then
  cat << END
SYNOPSIS
  $0 [working_directory]
  $0 -h: display this help





END
  exit 1
fi
#-e     When this option is on, if a simple command fails for any of the reasons listed in Consequences of
#       Shell  Errors or returns an exit status value >0, and is not part of the compound list following a
#       while, until, or if keyword, and is not a part of an AND  or  OR  list,  and  is  not  a  pipeline
#       preceded by the ! reserved word, then the shell shall immediately exit.

#-x     The  shell shall write to standard error a trace for each command after it expands the command and
#      before it executes it. It is unspecified whether the command that turns tracing off is traced.
#-o     Write the current settings of the options to standard output in an unspecified format.
set -xe
set -o pipefail

# Get a script directory, same as by $(dirname $0)
script_dir=${0%/*}
# Exporting variable for use in the parallel function
export absolute_script_dir=$(cd "${script_dir}" && pwd)
work_dir=${1:-${absolute_script_dir}/build} # $1 with the default
if [[ ! -d "${work_dir}" ]]; then
  mkdir "${work_dir}"
  chmod g+w "${work_dir}"
fi
cd "${work_dir}"
echo -e "\n## Running under ${USER}@${HOSTNAME} at ${PWD} ##\n"

if ! which parallel > /dev/null; then
  echo "Please install GNU Parallel"
  exit 1
fi

update_file_dir=update_files/
if [[ ! -d "${update_file_dir}" ]]; then
  mkdir "${update_file_dir}"
  chmod g+w "${update_file_dir}"
fi

# Remove leftover files if any


${absolute_script_dir}/download.sh

echo ***Comparing file list...
ls ${update_file_dir} | sed '/ESCI/d' > complete_filelist.txt

# Copy from ./update_files/ to current directory the WOS_CORE and .del files that have not been updated.
declare -i file_count=0
for core_file in $(grep -F --line-regexp --invert-match --file=finished_filelist.txt complete_filelist.txt); do
#TODO We can remove copying and just parse source update files after sorting (see below)
  cp -rf ${update_file_dir}${core_file} .
  ((++file_count))
done

if ((file_count == 0)); then
  echo "No new files to process"
  exit 0
fi

# Update WOS_CORE files one by one, in time sequence.
for core_file in $(ls *.tar.gz | sort -n); do
  echo "Processing CORE file: ${core_file}"

  # Unzip update file to a sub-directory.
  echo "***Unzipping update file: ${core_file}"
  tar --extract --file=${core_file} --gzip --verbose

  # Extract file name without extension
  xml_update_dir=${core_file%%.*}
  gunzip --force ${xml_update_dir}/*.gz

  for file in $(ls ${xml_update_dir}/*.xml | sort -n); do
    echo "**Parsing update file and writing in database: ${file}"
    parallel_cores=$(parallel --number-of-cores)
    parallel --halt soon,fail=1 --verbose --line-buffer --tagstring '|job#{#} s#{%}|' \
      "/anaconda2/bin/python ${absolute_script_dir} -filename ${file} -processes ${parallel_cores} -offset {} \
      -ncommit 1000" ::: $(seq -s ' ' ${parallel_cores})
    echo "Processed file: ${file}"
  done
  echo "WOS update process for ${core_file} completed"

  # language=PostgresPLSQL
  psql -v ON_ERROR_STOP=on \
       -c 'UPDATE update_log_wos SET last_updated = current_timestamp WHERE id = (SELECT max(id) FROM update_log_wos);'

  printf $core_file'\n' >> finished_filelist.txt
done
