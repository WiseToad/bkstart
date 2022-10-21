The bkstart is a small wrapper around great console backup utility, the Restic.
Needed to simplify periodic (not much frequent) routine tasks for manual backup
of my favorite filesystem branches.

Fearures:
- specific for each backup realm properties are stored in a distributed manner,
  nearby any filesystem branch intended to be backed up
- console output captured and persisted into log files separately for each repo
- launch of the most frequent tasks (actually the backup itself, and maybe 
  some others) now is pretty lightweight - cd into desired directory, then type
  "bkstart backup", that's all
- there are some minimal additional helper commands - info, scan and so
- maybe something else
