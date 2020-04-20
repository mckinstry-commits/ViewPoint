SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/* ==============================================================================
-- Author:		HH
-- Create date: 12/05/2012	TK-19960
-- Description:	Get SQL Job history (needs to be executed as viewpointcs since 
--				function gets data from msdb..sysjobhistory --> needs access)
=================================================================================*/
CREATE FUNCTION [dbo].[vfVAWDJobLogs]() 
RETURNS @ReturnTable TABLE 
( 
	JobName     VARCHAR(128) NOT NULL, 
	RunDateTime SMALLDATETIME NOT NULL, 
	RunDuration VARCHAR(10) NOT NULL, 
	RunStatus   INT NOT NULL, 
	StepId      INT NOT NULL, 
	[Message]   VARCHAR(max) NOT NULL, 
	[Server]    VARCHAR(max) NOT NULL 
) 
WITH EXECUTE AS 'viewpointcs' 
AS 
  BEGIN  
      WITH SqlJobHistory 
           AS (SELECT name, 
                      run_datetime, 
                      Substring(run_duration, 1, 2) + ':' 
                      + Substring(run_duration, 3, 2) + ':' 
                      + Substring(run_duration, 5, 2) AS RunDuration, 
                      run_status, 
                      step_id, 
                      [message], 
                      [server] 
               FROM   (SELECT j.name, 
                              run_datetime = CONVERT(DATETIME, Rtrim(run_date)) + 
                              ( run_time * 9 + run_time % 10000 * 6  + run_time % 100 * 10 ) / 216e4, 
                              run_duration = RIGHT('000000' + CONVERT(VARCHAR(6), run_duration ), 6), 
                              h.run_status, 
                              h.step_id, 
                              h.[message], 
                              h.[server] 
                       FROM   msdb..sysjobhistory h 
                              INNER JOIN msdb..sysjobs j 
                                      ON h.job_id = j.job_id) t) 
      INSERT INTO @ReturnTable 
      SELECT * 
      FROM   SqlJobHistory 
      RETURN 
  END 
GO
GRANT SELECT ON  [dbo].[vfVAWDJobLogs] TO [public]
GO
