#!/usr/bin/bash

header()
{
  echo ""
  echo "  VeST -- Version controllable SQLiTe"
  # Yes, the acronym is a bit of a stretch.
  echo ""
}

usage()
{
  header
  echo "  Usage:"
  echo "    vest <vestdb>"
  echo ""
  echo "  Overview:"
  echo "    VeST converts a binary SQLite database to text (using the sqldiff"
  echo "    program) which can then be managed properly in a version control"
  echo "    system like git."
  echo ""
  echo "    This is operated by just running the vest script on either the text"
  echo "    database (.sql) or the binary database (.db), this will sync one"
  echo "    version with another by modification time."
  echo ""
}

dependencies_and_exit()
{
  header
  echo "  Dependencies:"
  echo "    sqldiff    conversion from binary to text"
  echo "    sqlite3    conversion from text to binary"
}

convert_sql_to_db()
{
  # convert text to a binary SQLite database with extension .db
  TEXT_DB=$1
  BINARY_DB=$2
  rm -f "$BINARY_DB"
  echo "BEGIN_TRANSACTION;" > begin.sql
  echo "END_TRANSATION;" > end.sql
  grep -v 'sqlite_sequence' "$TEXT_DB" | sqlite3 "$BINARY_DB"
  rm -f begin.sql end.sql
}

convert_db_to_sql()
{
  # convert binary to a text database backup with extension .db
  BINARY_DB=$1
  TEXT_DB=$2
  sqldiff /dev/null "$BINARY_DB" > "$TEXT_DB"
}

sync()
{
  FILE="$1"
  EXT="${FILE##*.}"

  BINARY_DB=
  TEXT_DB=

  case $EXT in

    db)
      BINARY_DB="$FILE"
      TEXT_DB="${FILE/.db/.sql}"
      ;;

    sql)
      TEXT_DB="$FILE"
      BINARY_DB="${FILE/.sql/.db}"
      ;;

    *)
      header
      echo "  Unknown extension '$EXT'."
      echo "  Expected '.db' or '.sql'."
      exit 1
      ;;

  esac

  BINARY_AHEAD="null"
  if  stat "$BINARY_DB" &>/dev/null && stat "$TEXT_DB" &>/dev/null
  then

    if [[ $(stat -c "%Y" "$BINARY_DB") -gt $(stat -c "%Y" "$TEXT_DB") ]]
    then
      BINARY_AHEAD="true"
    else
      BINARY_AHEAD="false"
    fi

  elif stat "$BINARY_DB" &>/dev/null
  then

    BINARY_AHEAD="true"

  elif stat "$TEXT_DB" &>/dev/null
  then

    BINARY_AHEAD="false"

  fi

  if [ $BINARY_AHEAD == "null" ]
  then
    header
    echo "  Selected database doesn't exist."
    exit 1
  elif [ $BINARY_AHEAD == "true" ]
  then
    convert_db_to_sql "$BINARY_DB" "$TEXT_DB"
  else
    convert_sql_to_db "$TEXT_DB" "$BINARY_DB"
  fi

}

declare -a FILES
while [[ $# -gt 0 ]]
do

  key="$1"

  case $key in

    -h|--help)
      usage
      exit 0
      ;;

    *)
      FILES+=("$key")
      shift
      ;;

  esac

done

command -v "sqldiff" &> /dev/null || dependencies_and_exit
command -v "sqlite3" &> /dev/null || dependencies_and_exit


if [[ ${#FILES[@]} -eq 0 ]]
then
  usage
  exit 1
fi

for file in "${FILES[@]}"
do
  sync "$file"
done
