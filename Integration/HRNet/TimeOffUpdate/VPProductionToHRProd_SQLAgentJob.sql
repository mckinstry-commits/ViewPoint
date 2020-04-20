USE [msdb]
GO

/****** Object:  Job [Time Off Transfer From Viewpoint]    Script Date: 9/11/2015 7:35:10 AM ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    Script Date: 9/11/2015 7:35:10 AM ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Time Off Transfer From Viewpoint', 
		@enabled=1, 
		@notify_level_eventlog=3, 
		@notify_level_email=2, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'Viewpoint to HRDB on SESQL08  (2014.11.09 - LWO - Updated to switch source data from CGC to Viewpoint)

Original pre-conversion tables backed up as:
EmployeeTimeOff_20141109
TimeOffHistory_20141109
TimeOffHistoryLog_20141109
TimeOffHistoryLogAutoInsert_20141109
TimeOffHistoryLogHoursAdjust_20141109', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'sa', 
		@notify_email_operator_name=N'Brendan Mason', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Populate PRPTCH table with CGC Information]    Script Date: 9/11/2015 7:35:10 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Populate PRPTCH table with CGC Information', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=20, 
		@retry_interval=1, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @WeekEnding DATETIME
DECLARE @intWeekEnding INT
IF @WeekEnding IS NULL
BEGIN
  SET @WeekEnding=CAST(CONVERT(VARCHAR(10), DATEADD(d, -7, dbo.fnWeekEnding(GETDATE())), 111) AS DATETIME)
END
SET @intWeekEnding=CAST(CONVERT(VARCHAR(8),@WeekEnding,112) AS INT)

DELETE FROM McK_HRDB_TransferData.dbo.PRPTCH WHERE CHDTWE = @intWeekEnding

INSERT INTO McK_HRDB_TransferData.dbo.PRPTCH (CHEENO, CHOTHR, CHOTTY, CHDTWE) 
SELECT 
	t1.CHEENO
,	t1.CHOTHR
,	t1.CHOTTY
,	t1.CHDTWE
FROM
(
SELECT 
	CAST(prth.Employee AS int) AS CHEENO
,	cast(CASE 
		WHEN hqet.Description IN (''Other Earnings'') THEN SUM(prth.Hours)
		ELSE 0
	END AS decimal(18,2)) AS CHOTHR
,	
CASE 
WHEN prth.EarnCode = 5 THEN ''PT'' 
--WHEN prth.EarnCode = 6 THEN ''PT'' 
WHEN prth.EarnCode = 7 THEN ''FH'' 
WHEN prth.EarnCode = 8 THEN ''JD'' 
WHEN prth.EarnCode = 9 THEN ''BE'' 
WHEN prth.EarnCode = 10 THEN ''VA'' 
WHEN prth.EarnCode = 12 THEN ''PL'' 
ELSE prec.Description
END as CHOTTY	
,	CAST(COALESCE(CONVERT(CHAR(8),prth.PREndDate, 112),0) AS int) AS CHDTWE
FROM 
	[VIEWPOINTAG\VIEWPOINT].Viewpoint.dbo.mvwPRTH prth JOIN
	[VIEWPOINTAG\VIEWPOINT].Viewpoint.dbo.bPREH preh ON
		prth.PRCo=preh.PRCo
	AND prth.PRGroup=preh.PRGroup
	AND prth.Employee=preh.Employee JOIN
	[VIEWPOINTAG\VIEWPOINT].Viewpoint.dbo.PREC prec ON
		prth.PRCo=prec.PRCo
	AND prth.EarnCode=prec.EarnCode JOIN
	[VIEWPOINTAG\VIEWPOINT].Viewpoint.dbo.HQET hqet ON
		prec.EarnType=hqet.EarnType 
	--	LEFT OUTER JOIN	 HRNET.mnepto.EarnCodeMap  ecm ON
	--	prth.PRCo=ecm.PRCo
	--AND CAST(prth.EarnCode AS VARCHAR(10))=CAST(ecm.EarnCode AS VARCHAR(10)) COLLATE Latin1_General_CI_AS  
	JOIN	
	[VIEWPOINTAG\VIEWPOINT].Viewpoint.dbo.HQCO hqco ON
		prth.PRCo=hqco.HQCo
WHERE
--	LTRIM(RTRIM(ecm.ShortCode)) <> '''' 
--and	
--prth.udArea IS NOT NULL OR  ( 	prec.Description IN (SELECT  *  FROM [VIEWPOINTAG\VIEWPOINT].Viewpoint.dbo.PREC WHERE )
		
		prec.EarnType IN (6,7) AND prec.EarnCode in (5,6,7,8,10,12,14,9) 
GROUP BY
	prth.Employee
,	hqet.Description
,	CASE 
WHEN prth.EarnCode = 5 THEN ''PT'' 
--WHEN prth.EarnCode = 6 THEN ''PT'' 
WHEN prth.EarnCode = 7 THEN ''FH'' 
WHEN prth.EarnCode = 8 THEN ''JD'' 
WHEN prth.EarnCode = 9 THEN ''BE'' 
WHEN prth.EarnCode = 10 THEN ''VA'' 
WHEN prth.EarnCode = 12 THEN ''PL'' 
ELSE prec.Description
END 	
,	prth.PREndDate			
) t1 
WHERE CHDTWE = @intWeekEnding  and CHOTTY != ''Holiday''


', 
		@database_name=N'McK_HRDB_TransferData', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Run Transfer Sproc]    Script Date: 9/11/2015 7:35:10 AM ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Run Transfer Sproc', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=1, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'USE [McK_HRDB_TransferData]
GO

DECLARE	@return_value int

EXEC	@return_value = [dbo].[spCGCDATA_UpdateHoursUsedv3]
		@WeekEnding = NULL

SELECT	''Return Value'' = @return_value

GO
', 
		@database_name=N'McK_HRDB_TransferData', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Weekly', 
		@enabled=1, 
		@freq_type=8, 
		@freq_interval=12, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=1, 
		@active_start_date=20100113, 
		@active_end_date=99991231, 
		@active_start_time=220000, 
		@active_end_time=235959, 
		@schedule_uid=N'9c87220a-1b84-4aca-8ba4-b22d298c8d0b'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO


