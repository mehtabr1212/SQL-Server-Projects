# SQL Server Automated Backup and Point-in-Time Recovery (PITR)

A hands-on SQL Server learning project demonstrating backup automation,
backup-history monitoring, point-in-time recovery (PITR), and disaster
recovery after accidental table or database deletion.

> **Important:** This is a learning project. Run destructive operations
> only on a dedicated test SQL Server instance. Do not run the script
> from top to bottom without reviewing each section and adapting it to
> your environment.

## Project objectives

-   Create a sample `CompanyDB` database and an `Employees` table.
-   Insert sample records for testing.
-   Perform a full database backup.
-   Configure SQL Server Agent job steps for full, differential, and
    transaction log backups.
-   Review backup history using SQL Server metadata in `msdb`.
-   Practice restoring a database to a point before an accidental
    `DROP TABLE`.
-   Practice restoring a database after an accidental `DROP DATABASE`.
-   Verify the database and sample data after recovery.

## Technologies and concepts

-   Microsoft SQL Server and T-SQL
-   SQL Server Management Studio (SSMS)
-   SQL Server Agent
-   Full, differential, and transaction log backups
-   `FULL` recovery model
-   Backup compression and checksums
-   `msdb.dbo.backupset` and `msdb.dbo.backupmediafamily`
-   `RESTORE FILELISTONLY`, `NORECOVERY`, `RECOVERY`, `STOPAT`, and
    `MOVE`
-   Point-in-time recovery (PITR) and disaster recovery (DR)

## Prerequisites

-   A SQL Server instance with permission to create databases and
    perform backup/restore operations.
-   SQL Server Management Studio (SSMS).
-   SQL Server Agent available and running if you want to schedule jobs;
    it is not available in every SQL Server edition.
-   A dedicated test environment: this project deliberately drops a
    table and a database.
-   Backup folders created on the SQL Server host, with write access
    granted to the SQL Server Database Engine service account.

The sample script uses this Windows path:

``` text
D:\DBA Projects\Backups\
```

Create the required subfolders before running the backup commands:

``` text
D:\DBA Projects\Backups\Full\
D:\DBA Projects\Backups\Diff\
D:\DBA Projects\Backups\Trans\
D:\DBA Projects\Backups\Tail\
```

Change these paths if needed. SQL Server interprets these paths on the
database server, which may be different from the computer running SSMS.

## How to use the project

### 1. Create the sample database

Run **Section 1: Database Setup** only if `CompanyDB` does not already
exist. It creates the database, switches it to the `FULL` recovery
model, and creates the `Employees` table.

Run **Section 2: Insert Sample Data** to add sample employee records and
verify them with a `SELECT` query.

> The setup statements are not designed to be re-run blindly. If the
> database or table already exists, adjust the setup steps to avoid
> duplicate-object errors or duplicate sample data.

### 2. Take the initial full backup

Run **Section 3: Initial Full Backup** after inserting the sample data.
This creates a baseline backup for the restore chain.

### 3. Configure automated backup jobs

In SSMS, create separate SQL Server Agent jobs and place the
corresponding T-SQL from Section 4 into a T-SQL job step for each job:

  Job                      Example schedule   Backup type
  ------------------------ ------------------ -----------------
  Full backup              Daily at 00:00     Full database
  Differential backup      Every 6 hours      Differential
  Transaction log backup   Every 15 minutes   Transaction log

These are example schedules, not a universal backup policy. Choose
schedules and retention rules based on recovery point objectives (RPO),
recovery time objectives (RTO), workload, and available storage.

Configure job ownership, permissions, failure notifications, and
retention/cleanup separately. Email notifications require Database Mail
and an appropriately configured SQL Server Agent operator.

### 4. Monitor backup history

Run **Section 5: Backup History and Monitoring** to query backup
metadata in `msdb`. The query reports backup type, start and finish
time, backup size, compressed size, and backup file path.

You can also review job status in SQL Server Agent's Job Activity
Monitor. A successful job is useful evidence, but it does not replace
periodic restore testing.

### 5. Test recovery after accidental table deletion

**Section 6** simulates a dropped `Employees` table and demonstrates a
restore to a point before the deletion.

Before recovery:

1.  Confirm the full backup and any selected differential backup are
    valid and compatible.
2.  Identify all required transaction log backups and confirm the log
    chain has no gaps.
3.  Select a recovery time before the destructive operation.
4.  Confirm the actual backup filenames and destination paths.
5.  Take a tail-log backup only when appropriate and possible.

The script contains example filenames and a timestamp from an earlier
test. Replace them with the files and times from your own run. Restore
the full backup with `NORECOVERY`, then the compatible differential
backup if used, followed by every required transaction log backup in the
correct sequence. Apply `STOPAT` on the appropriate final log restore
and use `RECOVERY` to bring the database online.

### 6. Test disaster recovery after database deletion

**Section 7** simulates dropping `CompanyDB` and restoring it from
backups.

Before running the destructive statement, verify that you are connected
to a dedicated test instance and have confirmed the backups you intend
to use. Use `RESTORE FILELISTONLY` to inspect logical file names, then
adjust `MOVE` destinations to valid paths on the SQL Server host.

Restore the full backup, the compatible differential backup if
available, and all required transaction log backups in the correct LSN
sequence. Complete the sequence with `RECOVERY` only after applying the
intended restore chain.

After recovery, verify database status and data using the queries in the
script.

## Important recovery notes

-   **A backup file is not proof of recoverability.** Test restores
    regularly and verify the recovered data.
-   **The log backup chain must be continuous.** Do not select log files
    based only on filenames or timestamps; verify that each backup
    belongs to the required sequence.
-   **Differential backups depend on a base full backup.** Use a
    differential backup compatible with the full backup restored before
    it.
-   **Point-in-time recovery requires suitable log backups.** The target
    time must be covered by the available log chain.
-   **Tail-log backup availability depends on the failure scenario.**
    After a database has been dropped, do not assume a tail-log backup
    can be taken.
-   **`WITH REPLACE` can overwrite an existing database.** Use it only
    after confirming the target and data-loss implications.
-   **`WITH NORECOVERY` leaves the database in the `RESTORING` state**
    so more backups can be applied. `WITH RECOVERY` completes the
    restore sequence.
-   **File-system permissions matter.** The SQL Server Database Engine
    service account must be able to access the relevant backup and
    data-file locations.
-   **The script uses hard-coded filenames and timestamps.** Replace
    them with actual files and recovery times from your own test.
-   **Undocumented diagnostics:** `fn_dblog()` is an undocumented
    diagnostic function. It is not a substitute for a valid backup chain
    or a supported recovery method and should not be used casually on
    production systems.

## Expected learning outcomes

By completing this project in a test environment, you can practice:

-   Creating and validating a SQL Server backup plan.
-   Understanding full, differential, and transaction log backup
    relationships.
-   Automating backup commands through SQL Server Agent.
-   Monitoring backup metadata and job status.
-   Planning and executing point-in-time recovery.
-   Restoring a database from a backup chain and validating the result.

## Safety disclaimer

This repository is for educational and portfolio demonstration purposes
only. It is not a production-ready backup policy. Review every command,
confirm the target SQL Server instance and file paths, and maintain
independent backups before destructive operations. Never test
`DROP TABLE`, `DROP DATABASE`, or restore commands against a production
database.

## Author

**Mehtab Singh Randhaw**

Project focus: SQL Server database backup, monitoring, point-in-time
recovery, and disaster recovery.
