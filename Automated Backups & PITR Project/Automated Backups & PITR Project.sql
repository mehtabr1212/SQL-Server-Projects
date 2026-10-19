/*
===============================================================================
Project: SQL Server Automated Backup and Point-In-Time Recovery (PITR)
Database: CompanyDB
Purpose:
    1. Create a sample database and employee table.
    2. Demonstrate full, differential, and transaction log backups.
    3. Demonstrate SQL Server Agent backup job steps and schedules.
    4. Monitor backup history using SQL Server system tables.
    5. Test recovery from accidental table deletion.
    6. Test recovery after database deletion.

Important:
    - This is a learning project. Run destructive statements only in a test environment.
    - Backup directories must exist, and the SQL Server Database Engine service account must have the required file-system permissions.
    - This file contains separate sections for manual execution and SQL Server Agent job steps. Do not execute the entire file blindly.
    - Always verify backup compatibility and the complete restore chain before restoring.
===============================================================================
*/


/*
===============================================================================
Section 1: Database Setup
===============================================================================
*/
-- Run this only if CompanyDB does not already exist.
create database companydb;

-- Enable the FULL recovery model.
-- This supports transaction log backups and point-in-time recovery (PITR), provided an appropriate full backup and a continuous log backup chain exist.
alter database companydb set recovery full;

-- Create the sample Employees table.
use companydb;
create table employees (ID int identity primary key, name varchar(50), location varchar(100), mobilenumber varchar(15));


/*
===============================================================================
Section 2: Insert Sample Data
===============================================================================
*/
insert into employees(name, location, mobilenumber) values
('Aarav Sharma', 'Mumbai, Maharashtra', '+91 9820012345'),
('Vihaan Patel', 'Ahmedabad, Gujarat', '+91 9712345678'),
('Aditya Iyer', 'Chennai, Tamil Nadu', '+91 9444012345'),
('Sai Reddy', 'Hyderabad, Telangana', '+91 9848012345'),
('Arjun Nair', 'Kochi, Kerala', '+91 9846054321'),
('Rohan Das', 'Kolkata, West Bengal', '+91 9830098765'),
('Vivaan Joshi', 'Pune, Maharashtra', '+91 9922012345'),
('Ananya Rao', 'Bengaluru, Karnataka', '+91 9845012345'),
('Diya Banerjee', 'Kolkata, West Bengal', '+91 9831054321'),
('Meera Krishnan', 'Chennai, Tamil Nadu', '+91 9445098765'),
('Isha Gupta', 'Delhi, NCR', '+91 9810012345'),
('Avani Deshmukh', 'Nagpur, Maharashtra', '+91 9823054321'),
('Pranav Choudhury', 'Guwahati, Assam', '+91 9435012345'),
('Karan Malhotra', 'Chandigarh, Punjab', '+91 9814054321'),
('Kabir Singh', 'Amritsar, Punjab', '+91 9815098765'),
('Ishaan Verma', 'Lucknow, Uttar Pradesh', '+91 9935012345'),
('Reyansh Mishra', 'Patna, Bihar', '+91 9431012345'),
('Aadhya Mishra', 'Bhopal, Madhya Pradesh', '+91 9425054321'),
('Saanvi Mishra', 'Jaipur, Rajasthan', '+91 9829012345'),
('Zara Khan', 'Mumbai, Maharashtra', '+91 9819098765');

---Verify the sample records before taking the initial backup
select * from Employees;


/*
===============================================================================
Section 3: Initial Full Backup
===============================================================================
*/
-- Take an initial full backup to establish the starting point for the backup and restore chain.
-- Run this after the database and sample data have been created.
-- Ensure the destination directory exists and is writable by SQL Server.
backup database [CompanyDB]
to disk = 'D:\DBA Projects\Backups\Full\CompanyDB_Initial.bak'
with compression, checksum;


/*
===============================================================================
SECTION 4: SQL SERVER AGENT BACKUP JOB STEPS
===============================================================================
Create three separate SQL Server Agent jobs in SSMS.
Place the corresponding T-SQL script below in each job's T-SQL step.

Suggested schedules:
    Full backup:          Once daily at 00:00.
    Differential backup:  Every 6 hours.
    Transaction log:      Every 15 minutes.

Configure failure email notifications through SQL Server Agent after Database Mail and an appropriate Agent operator have been configured.
*/
/*-----------------------------------------------------------------------------
4.1 AUTOMATED FULL BACKUP JOB STEP
-----------------------------------------------------------------------------*/
--- Generate a timestamped filename to distinguish each full backup.
declare @DynamicFileName varchar(150);
set @DynamicFileName = 'D:\DBA Projects\Backups\Full\CompanyDB_Full_' +
format(getdate(), 'yyyyMMdd_HHmmss') + '.bak';

-- Take a compressed full backup and request backup checksum generation.
backup database [CompanyDB]
to disk = @DynamicFileName
with compression, checksum;

/*-----------------------------------------------------------------------------
4.2 AUTOMATED DIFFERENTIAL BACKUP JOB STEP
-----------------------------------------------------------------------------*/
-- Generate a timestamped filename for the differential backup.
declare @DynamicFileName varchar(150);
set @DynamicFileName = 'D:\DBA Projects\Backups\Diff\CompanyDB_Diff_' + 
format(getdate(), 'yyyyMMdd_HHmmss') + '.bak';

-- A differential backup contains changes since its applicable full backup.
backup database [CompanyDB]
to disk = @DynamicFileName
with differential, compression, checksum;

/*-----------------------------------------------------------------------------
4.3 AUTOMATED TRANSACTION LOG BACKUP JOB STEP
-----------------------------------------------------------------------------*/
-- Generate a timestamped filename for the transaction log backup.
declare @DynamicFileName VARCHAR(150);
set @DynamicFileName = 'D:\DBA Projects\Backups\Trans\CompanyDB_Trans_Log_' + 
format(getdate(), 'yyyyMMdd_HHmmss') + '.trn';

-- Back up transaction log records since the previous applicable log backup.
-- The database must be using FULL or BULK_LOGGED recovery and must have an established log backup chain.
-- Each run uses a new filename, so NOFORMAT and NOINIT are not required here.
backup log [CompanyDB] 
to disk = @DynamicFileName 
with compression, checksum;


/*
===============================================================================
SECTION 5: BACKUP HISTORY AND MONITORING
===============================================================================
*/ -- Review SQL Server's backup metadata recorded in the msdb database.
   -- Backup types: D = Full database backup, I = Differential database backup, L = Transaction log backup
   -- This query shows backup history and the associated backup file path.
   -- You can also use Job Activity Monitor under SQL Server Agent to view the status of the jobs.
select top (50) bs.database_name,
    case bs.type
        when 'D' then 'Full'
        when 'I' then 'Differential'
        when 'L' then 'Log'
        else bs.type
    end as backuptype,
    bs.backup_start_date, bs.backup_finish_date,
    bs.backup_size / 1048576.0 as backupsizemb, bs.compressed_backup_size / 1048576.0 as compressedsizemb,
    bmf.physical_device_name as backupfile
from msdb.dbo.backupset as bs
inner join msdb.dbo.backupmediafamily as bmf
    on bs.media_set_id = bmf.media_set_id
where bs.database_name = N'CompanyDB'
order by bs.backup_finish_date desc;


/*
===============================================================================
SECTION 6: TEST CASE 1 — ACCIDENTAL TABLE DELETION AND PITR
===============================================================================
Objective: Demonstrate recovery of Employees by restoring CompanyDB to a point before the DROP TABLE transaction.
Before testing:
    - Confirm that a valid full backup exists.
    - Confirm that the selected differential backup, if used, belongs to that full backup.
    - Identify every required transaction log backup in LSN order.
    - Record the intended recovery time.
    - Confirm that the tail-log backup destination directory exists.

The following timestamps document the original test run. Update them when repeating the test; do not assume that old filenames will exist.
*/
-- Review the current employee data before droping the table.
select * from Employees

-- Record the approximate time immediately before the DROP TABLE statement.
select sysdatetime()  ----- Time: 2026/10/13 15:48:09:457

-- TEST ONLY: Delete the Employees table to simulate an accidental operation.
drop table Employees;  --- Droping a table.

/*
Optional diagnostic:
fn_dblog() is an undocumented diagnostic function. Its output is not a substitute for a valid backup chain or a supported restore procedure. Avoid unrestricted use on production systems because of potential overhead.
*/
use CompanyDB
select [transaction id], [begin time], [transaction name], [transaction sid] from fn_dblog(null, null)
where [transaction name] like '%drop%';

/*
-----------------------------------------------------------------------------
6.1 TAKE A TAIL-LOG BACKUP, IF THE LOG IS STILL ACCESSIBLE
-----------------------------------------------------------------------------
A tail-log backup captures log records not yet backed up, where SQL Server can still access the required transaction log. It is not possible in every failure scenario.
WITH NORECOVERY takes the database offline into the RESTORING state after the backup. Do this only when you are ready to proceed with the restore.
*/
--- TEST ONLY: Confirm the database and log are accessible before running.
use master;
backup log companydb 
to disk = 'D:\DBA Projects\Backups\Tail\CompanyDB_TailLog.trn' 
with norecovery;

/*
-----------------------------------------------------------------------------
6.2 RESTORE THE FULL BACKUP
-----------------------------------------------------------------------------
Use the actual full backup filename selected for this recovery test.
The selected full backup must be compatible with the subsequent differential and transaction log backups.
WITH NORECOVERY leaves the database in the RESTORING state so additional backups can be applied.
WITH REPLACE can overwrite an existing database. Use it only after confirming that overwriting can be done.
*/
restore database companydb 
from disk = 'D:\DBA Projects\Backups\Full\CompanyDB_Full_20261012_040004.bak' 
with norecovery, replace;

/*
-----------------------------------------------------------------------------
6.3 RESTORE THE COMPATIBLE DIFFERENTIAL BACKUP
-----------------------------------------------------------------------------
Skip this step only if no suitable differential backup is being used.
The differential must be based on the full backup restored in the previous step. Otherwise, SQL Server may reject the restore sequence.
*/
restore database CompanyDB
from disk = 'D:\DBA Projects\Backups\Diff\CompanyDB_Diff_20261012_040004.bak'
with norecovery;

/*
-----------------------------------------------------------------------------
6.4 RESTORE ALL REQUIRED TRANSACTION LOG BACKUPS
-----------------------------------------------------------------------------
Restore the required log backups in chronological LSN order.
There may be multiple log backups between the full/differential backup and the tail-log backup. Apply all required backups without gaps.
Replace the example filename with the actual backup file.
*/
restore log CompanyDB
from disk = 'D:\DBA Projects\Backups\Trans\CompanyDB_Trans_Log_20261013_154501.trn'
with norecovery;

/*
-----------------------------------------------------------------------------
6.5 POINT-IN-TIME RECOVERY
-----------------------------------------------------------------------------
Choose a STOPAT time before the DROP TABLE transaction took effect. The time below is from the original test done.
The target must fall within the time range covered by the applicable log backup. The log backup chain must be complete.
Use the tail-log backup here only if it is the next valid backup in the restore sequence. If more log backups are required, restore them first.
WITH RECOVERY completes the restore and brings the database online.
*/
restore log companydb 
from disk = 'D:\DBA Projects\Backups\Tail\CompanyDB_TailLog.trn' 
with recovery, 
stopat = '2026-10-13 15:48:09';

/*
-----------------------------------------------------------------------------
6.6 VERIFY THE RECOVERED TABLE
-----------------------------------------------------------------------------
Expected result: The Employees table exists and contains the records captured before the droping the table, including transactions committed before the selected recovery point.
*/
use companydb;
select * from employees;

-- Expected result for the original test: PASS.



/*
===============================================================================
SECTION 7: TEST CASE 2 — DATABASE DELETION AND DISASTER RECOVERY
===============================================================================
Objective: Demonstrate recovery of the entire CompanyDB database from a valid full, differential, and transaction log backup chain.
WARNING: The following DROP DATABASE statement permanently removes the test database from the instance. Run this section only in a test environment.
IMPORTANT: Once the database has been dropped, do not assume a tail-log backup can be taken. Use the latest available valid backup chain and document the recovery point and any transactions that may be lost.
*/

use master;
-- Optional: SINGLE_USER WITH ROLLBACK IMMEDIATE can disconnect other sessions and roll back their active transactions.
-- Use it only if needed and after confirming that this is a test database.
-- ALTER DATABASE CompanyDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;

-- TEST ONLY: Simulate a database deletion incident.
drop database CompanyDB;

-- Record the time of the test operation.
select sysdatetime()  --- Time: 2026-10-16 12:53:25.5316329

/*
-----------------------------------------------------------------------------
7.1 INSPECT THE FULL BACKUP'S LOGICAL FILE NAMES
-----------------------------------------------------------------------------
RESTORE FILELISTONLY returns the logical data and log file names contained in the selected backup. Use the exact LogicalName values in the MOVE options if relocating the restored files.
*/
restore filelistonly
from disk = 'D:\DBA Projects\Backups\Full\CompanyDB_Full_20261016_100049.bak';

/*
-----------------------------------------------------------------------------
7.2 RESTORE THE FULL BACKUP
-----------------------------------------------------------------------------
MOVE relocates the restored data and log files to the specified physical paths. Ensure those paths are valid and are not already occupied by files that must be preserved.
WITH NORECOVERY leaves the database ready for subsequent differential and transaction log restores.
*/
use master;
restore database CompanyDB
from disk = 'D:\DBA Projects\Backups\Full\CompanyDB_Full_20261016_100049.bak'
with move 'CompanyDB' to 'D:\DBA Projects\Backups\CompanyDB.mdf',
     move 'CompanyDB_log' to 'D:\DBA Projects\Backups\CompanyDB_log.ldf',
     norecovery, checksum, stats = 10;

/*
-----------------------------------------------------------------------------
7.3 RESTORE THE COMPATIBLE DIFFERENTIAL BACKUP
-----------------------------------------------------------------------------
Restore a differential only if it is based on the full backup restored above. If no suitable differential is available, skip this step and proceed with the required transaction log backups.
*/
restore database CompanyDB
from disk = 'D:\DBA Projects\Backups\Diff\CompanyDB_Diff_20261016_120001.bak'
with norecovery, checksum, stats = 10;

/*
-----------------------------------------------------------------------------
7.4 RESTORE THE REQUIRED TRANSACTION LOG BACKUPS
-----------------------------------------------------------------------------
Apply each required transaction log backup in the correct LSN sequence. Do not skip a required log backup or select files based only on timestamps.
*/
restore log CompanyDB
from disk = 'D:\DBA Projects\Backups\Trans\CompanyDB_Trans_Log_20261016_124504.trn'
with norecovery, checksum, stats = 10;

/*
-----------------------------------------------------------------------------
7.5 APPLY THE FINAL REQUIRED LOG BACKUP AND COMPLETE RECOVERY
-----------------------------------------------------------------------------
Replace the placeholder filename below with the actual next valid log backup, if one is required.
If the preceding log backup is already the last required backup, restore that backup with RECOVERY instead of running an additional restore command.
If the desired recovery point is earlier than the end of the available log chain, use STOPAT on the appropriate final log restore.
CHECKSUM requests validation when checksum information is available in the backup set. If it's not available in the backup set, then remove the CHECKSUM from RESTORE query.
*/
restore log CompanyDB
from disk = 'D:\DBA Projects\Backups\Trans\YourFinalLogBackup.trn'
with recovery, checksum, stats = 10;

/*
-----------------------------------------------------------------------------
7.6 VERIFY THE RECOVERED DATABASE AND DATA
-----------------------------------------------------------------------------
Expected result: CompanyDB is ONLINE, and the Employees table and its data are available up to the recovery point represented by the restored backup chain.
*/
use CompanyDB;

select name, state_desc from sys.databases
where name = 'CompanyDB';

select * from Employees;

-- Expected result for the original test: PASS.