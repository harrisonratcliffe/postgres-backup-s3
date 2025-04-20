# PostgreSQL Backup S3 Script

This script automates the process of backing up a PostgreSQL database to an S3-compatible storage solution, using Amazon's CLI tools. The backup is compressed and can optionally send a heartbeat request to a monitor service like [Uptime Robot](https://uptimerobot.com/?red=harris0cbaa4).

## Features

- **Configurable database connection** using environment variables.
- **Local backup generation** to a specified directory.
- **Upload to S3-compatible storage**.
- **Optional deletion of local backup** after successful upload.
- **Heartbeat monitoring** to track backup success.
- **Automatic cleanup of old backups** based on retention policy.
- **Logging** backups to a file

## Prerequisites

Before running the script, ensure you have the following:

- PostgreSQL installed and accessible.
- **AWS CLI** installed and configured with the appropriate permissions to access the specified S3 bucket.  
  For installation instructions, please refer to the [AWS CLI installation guide](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html).
- After installation, run the following command to authenticate:

```bash
   aws configure
```

   You will be prompted to enter your Access Key ID, Secret Access Key, region, and output format.

- `gzip` for compressing backups.
- Optional: `curl` for heartbeat monitoring.
- Bash shell for executing the script.

## Downloading the Backup Script

You can download the backup script using the `wget` command:

```bash
wget https://raw.githubusercontent.com/harrisonratcliffe/postgres-backup-s3/refs/heads/main/backup-postgres.sh
```

## Configuration

Before running the script, configure the following variables directly in the script:

- **Database Configuration**:
    - `DB_USER`: PostgreSQL username.
    - `DB_PASSWORD`: PostgreSQL password.
    - `DB_NAME`: Name of the database to back up.
    - `DB_HOST`: Host of the PostgreSQL server (default is `localhost`).
- **S3 Configuration**:
    - `BUCKET_NAME`: Name of the S3 bucket where backups will be stored.
    - `S3_ENDPOINT`: S3 endpoint URL (for example, if using Cloudflare).
    - `LOCAL_BACKUP_DIR`: Local directory path where backups will be created.
    - `S3_BACKUP_DIR`: Prefix path in the S3 bucket for backup files.
- **Optional Features**:
    - `DELETE_LOCAL_BACKUP`: Set to `true` to delete local backup after upload (default is `true`).
    - `SEND_HEARTBEAT`: Set to `true` to send a heartbeat notification (default is `false`).
    - `HEARTBEAT_URL`: URL for the heartbeat monitor.
    - `BACKUP_RETENTION_DAYS`: Number of days to keep local backups (default is `30`, set to `0` to disable).
    - `ENABLE_LOGGING`: Enable logging for backups to a specified log file.
    - `LOG_FILE`: The file to log to.

## Daily Cron Job Setup

To automate the backup process, you can set up a daily cron job. Add the following line to your crontab:

```bash
0 0 * * * /scripts/backup-postgres.sh > /dev/null 2>&1
```

This will execute the script at midnight every day.

A useful tool to calculate the desired cron frequency is [crontab.guru](https://crontab.guru).

## Usage

1. Make the script executable:

```bash
   chmod +x backup-postgres.sh
```

2. Run the script:

```bash
   ./backup-postgres.sh
```

## Error Handling

The script will exit and display an error message if:

- The PostgreSQL backup operation fails.
- The upload to S3 fails.
- Heartbeat notification fails (if enabled).

## Cleaning Up Old Backups

The script will automatically delete backups that are older than the specified number of days set in `BACKUP_RETENTION_DAYS`. Set it to `0` if you wish to keep all backups indefinitely.

## Notes

- Ensure that your PostgreSQL password does not contain characters that may be interpreted by the shell. You may want to escape such characters or use alternative methods to handle passwords securely.
- Adjust the permissions of `LOCAL_BACKUP_DIR` as necessary to ensure the script has write access.
- Test the script in a safe environment before deploying it for production backups.

## License

This project is covered under the [MIT](https://choosealicense.com/licenses/mit/) License. For more details, refer to the [LICENSE](https://github.com/harrisonratcliffe/postgres-backup-s3/blob/main/LICENSE) file.
