SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

USE ViewpointProphecy
GO

if exists ( select * from INFORMATION_SCHEMA.ROUTINES where ROUTINE_NAME='mspLogProphecyAction' and ROUTINE_SCHEMA='mers' and ROUTINE_TYPE='PROCEDURE' )
begin
	print 'DROP PROCEDURE mers.mspLogProphecyAction'
	DROP PROCEDURE mers.mspLogProphecyAction
end
go

print 'CREATE PROCEDURE mers.mspLogProphecyAction'
go

CREATE PROCEDURE [mers].[mspLogProphecyAction]
(
	@User		bVPUserName 
,   @ActionInt	SMALLINT
,	@Version	VARCHAR(6)
,	@Company    bCompany
,   @Contract	bContract
,	@Job		bJob
,	@bMonth		bMonth
,	@BatchId	bBatchID
,	@Details    VARCHAR(50)
,	@ErrorTxt	VARCHAR(255)
)
AS
-- ========================================================================
-- Object Name: mers.mspLogProphecyAction
-- Author:		Ziebell, Jonathan
-- Create date: 7/15/2016
-- Description: Procedure to populate the Prophecy log table.
-- Update Hist: USER--------DATE-------DESC-----------
-- ========================================================================
DECLARE @Action AS VARCHAR(20)
	, @ActionDate AS DateTime 

SET @Action = CASE @ActionInt
				WHEN 1 THEN 'REPORT'
                WHEN 2 THEN 'NEW COST JECT'
				WHEN 3 THEN 'LOAD COST JECT'
				WHEN 4 THEN 'SAVE COST JECT'
				WHEN 5 THEN 'NEW REV JECT'
				WHEN 6 THEN 'LOAD REV JECT'
				WHEN 7 THEN 'SAVE REV JECT'
				WHEN 8 THEN 'INVALID USER'
				WHEN 9 THEN 'ERROR'
				WHEN 10 THEN 'CANCEL COST'
				WHEN 11 THEN 'POST COST'
				WHEN 12 THEN 'CANCEL REV'
				WHEN 13 THEN 'POST REV'
				WHEN 14 THEN 'ERROR POST REV'
				WHEN 15 THEN 'ERROR POST COST'
				WHEN 16 THEN 'ERROR SAVE REV'
				WHEN 17 THEN 'ERROR SAVE COST'
				ELSE 'UNKNOWN' 
		END

SET @ActionDate = SYSDATETIME();

BEGIN
	INSERT INTO mers.ProphecyLog (VPUserName, DateTime, Version, JCCo, Contract, Job, Mth, BatchId, Action, Details, ErrorText)
		VALUES (@User, @ActionDate,	@Version, @Company, @Contract, @Job, @bMonth, @BatchId, @Action, @Details, @ErrorTxt)
END

GO
