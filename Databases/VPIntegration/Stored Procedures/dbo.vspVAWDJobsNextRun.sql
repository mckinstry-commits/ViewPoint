SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspVAWDJobsNextRun]
/************************************************************************
* Created:	DW 01/14/13   
* Modified:  
*
* Usage:
*   Returns the next scheduled run date for a notifier job.  
*
* Inputs:
*	@jabname		Job Name
*
* Outputs:
*	date of next run 
*
*************************************************************************/

(@jobname sysname = null)
WITH EXECUTE AS 'viewpointcs'
as
set nocount on

DECLARE @job_results TABLE  
( 
   job_id                UNIQUEIDENTIFIER NOT NULL, 
   last_run_date         INT NOT NULL, 
   last_run_time         INT NOT NULL,
   next_run_date         INT NOT NULL, 
   next_run_time         INT NOT NULL, 
   next_run_schedule_id  INT NOT NULL, 
   requested_to_run      INT NOT NULL,
   request_source        INT NOT NULL, 
   request_source_id     sysname collate database_default NULL, 
   running               INT NOT NULL,
   current_step          INT NOT NULL, 
   current_retry_attempt INT NOT NULL, 
   job_state             INT NOT NULL 
) 
	
INSERT @job_results 
EXEC master.dbo.xp_sqlagent_enum_jobs @is_sysadmin = 1, @job_owner = '' 

SELECT Top 1 next_scheduled_run_date = CASE
											WHEN next_run_date = 0 OR next_run_date IS NULL THEN NULL
											ELSE CONVERT(smalldatetime, Rtrim(next_run_date)) + ( next_run_time * 9 + next_run_time % 10000 * 6  + next_run_time % 100 * 10 ) / 216e4
										END
FROM   @job_results r 
INNER JOIN msdb..sysjobs j ON r.job_id = j.job_id 
WHERE  j.name = @jobname 

RETURN	
			
GO
GRANT EXECUTE ON  [dbo].[vspVAWDJobsNextRun] TO [public]
GO
