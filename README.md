# Backup and Restore Tool

This tool allows you to easily backup and restore directories of files. All backups are encrypted for security.

## Usage

### before running script

Make sure you have execution permission to run without errors, if not,
please run this command: 

```bash
chmod +x backup.sh restore.sh backup_restore_lib.sh 
```


### Backup

To run a backup:

```bash
./backup.sh <source_dir> <backup_dir> <encrypt_key> <days>
```

- `<source_dir>` - Path to source directory to backup
- `<backup_dir>` - Path to place backup archives 
- `<encrypt_key>` - Passphrase to use for encryption
- `<days>` - Only backup files modified in past n days

Example:

```
./backup.sh /home/user/documents /backups/documents.bak mysecretkey 3 
```

This will backup `/home/user/documents` to `/backups/documents.bak`, encrypting with passphrase `mysecretkey` and only including files modified in the last 7 days.

The script will create dated subdirectories within `<backup_dir>` for each backup session.

You will be prompted to enter a remote host and directory to copy the backup to.

### Restore

To restore from a backup:

```
./restore.sh <backup_dir> <restore_dir> <decrypt_key> 
```

- `<backup_dir>` - Directory containing the backup archives
- `<restore_dir>` - Destination to restore files to 
- `<decrypt_key>` - Passphrase for decrypting archives

Example: 

```
./restore.sh /backups/documents.bak /home/user/documents-restored mysecretkey
```

This will restore the archives in `/backups/documents.bak` to `/home/user/documents-restored`, decrypting with the `mysecretkey` passphrase.

All encrypted tar archives will be decrypted to a temporary directory before extracting to the restore directory.

### Cron Job:

   
   To schedule the backup script to run daily, run below command:
```
crontab -e
```
add this entry in the crontab:

    0 0 * * * /path/to/backup.sh /path/to/source/directory /path/to/backup/directory encryption_key days
