# VeST - Version controllable SQLiTe

Backup SQLite to a list of SQL commands using `sqldiff`, this can be entered
into version control easily, then recover the database from the list of commands
using the sqlite3 program.

Invocation is easy:

```bash
./vest <file>
```

`vest` will dumbly decide whether the file is a binary SQLite database or a text
list of commands by inspecting the extension of the file passed. 

`.sql` is a list of sql commands. `.db` indicates a binary database.

The modification time of the database and the sql file will be checked, the most
recent one will be converted to the other.

This could be added into a git hook so its kept up to date.

# Installation

Copy `vest` somewhere into your path.
