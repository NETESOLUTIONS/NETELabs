# VJ Davey
# This script is used to create quarterly dumps of the postgres data for our end users
# Usage:
#       sh create_quarterly_dumps.sh output_dir
# where $output_dir specifies the directory we want all the dump files to go to
# Date 10/11/17


# Record start time
printf 'STARTED:\t\t\t'; date

# Take in user input for output directory for files
output_dir=$1

# Manually build and maintain a list of exclusion tables for the quarterly dump process. These are the tables with matching prefixes for the main data sources that we do not want pushed to the client.
exclude_tables="cg_ref_counts derwent_familyid derwent_patents_filterred_to_nih_support fda_drug_patents fda_purple_cber_book fda_purple_cder_book wos_patent_mapping wos_pmid_manual_mapping wos_pmid_mapping"
exclude_string=""

# Build the exclusion string (this sets exclusion options for the given tables and their sequences on the pg_dump command).
for table in $exclude_tables ; do
        exclude_string=$exclude_string'-T '$table' -T '$table'*_seq '
done

# Build the different dump files
data_sources="cg ct fda derwent"
for prefix in $data_sources; do
        pg_dump pardi --section=pre-data --section=data --no-owner --no-privileges --no-tablespaces -t $prefix'_*' $exclude_string > $output_dir'/'$prefix'_dump.sql'
        echo '...SQL dump script created...'
        gzip $output_dir'/'$prefix'_dump.sql' &
        #send messages to prevent timeouts
        while [ "$(ps $! | grep $!)" ]; do
          sleep 15; echo 'still working to compress '$prefix' data...'
        done
        printf 'FILE '$output_dir'/'$prefix'_dump.sql CREATED AND COMPRESSED:\t'; date
done

# Record end time
printf 'FINISHED:\t\t\t'; date
