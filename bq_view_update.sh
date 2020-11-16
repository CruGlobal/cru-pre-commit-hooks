#!/bin/sh
set -e

DW_TF_BASE="applications/data-warehouse"
BQ_SQL_DIR="$DW_TF_BASE/big-query/views"

tf_check_and_update()
{
    TF_PATH=$1
    if [`git diff --name-only --staged | grep $TF_PATH/*.tf | wc -l` -eq 0 ]
    then
      echo "# View update on $(date)" >> $TF_PATH/trigger.tf # dummy tf file for triggering Atlantis
      echo "A Big Query sql file is staged for commit but no tf files were updated."
      echo "Stage the file $TF_PATH/trigger.tf and rerun the commit."
    else
      echo "SQL and tf updates are ok."
    fi
}

if [ `git diff --name-only --staged | grep $BQ_SQL_DIR/.*\.sql | wc -l` -gt 0 ]
then
  echo "Checking Stage tf files"
  tf_check_and_update $DW_TF_BASE/stage/big-query/views

  echo "Checking Prod tf files"
  tf_check_and_update $DW_TF_BASE/prod/big-query/views
else
  echo "No Big Query sql updates"
fi