## CycleLogs ##

Recycle logs directory regurlarly depending on the policy applied.

Syntax:
```
    CycleLogs.sh [OPTIONS]
```

Specials symlinks '**today**', '**yesterday**' & '**last**' will be created in the directory.  
They should be used to efficiently manage the logs on the system:  
```
    myprogram.sh >$HOME/logs/today/myprogram.log
```

### OPTIONS ###

1- Specify the parameters on the command line with the following format:  
```
    directory:period:behavior
```
**directory** : the directory to use for the logs recycling  

| Period  | Description                           |
| --------|---------------------------------------|
| weekly  | the logs will be recycled every week  |
| monthly | the logs will be recycled every month |
| yearly  | the logs will be recycled every year  |

| Behavior | Description                             |
| ---------|-----------------------------------------|
| purge    | logs will be removed from the directory |
| archive  | logs will be archived, then removed (1) |

(1) Logs will be archived in `directory/.archive`.



2- Use the '-f' (or --file) flag to load the configuration from a file:
```
    CycleLogs.sh -f <configuration file>
```

Each lines of the file should respect the same format than the command line.  
However, comments '#' and empty line are authorized to add clarity and information.


### NOTES ###

Script should be run everyday via crontab to update the current working directory as well as the symlinks.  
It must be one of the 1st script executed in the morning to ensure logs are stored correctly. 

Example with Crontab, job running everyday at 00:05 :
```
05 00 * * * ${HOME}/scripts/bin/CycleLogs.sh -f ${HOME}/scripts/conf/CycleLogs.conf
```