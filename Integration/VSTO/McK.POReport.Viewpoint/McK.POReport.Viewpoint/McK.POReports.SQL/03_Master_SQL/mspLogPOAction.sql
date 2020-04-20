USE Viewpoint
GO

If EXISTS ( Select * From INFORMATION_SCHEMA.ROUTINES Where ROUTINE_NAME='mspLogPOAction' and ROUTINE_SCHEMA='dbo' and ROUTINE_TYPE='PROCEDURE' )
Begin
	Print 'DROP PROCEDURE dbo.mspLogPOAction'
	DROP PROCEDURE dbo.mspLogPOAction
End
GO

Print 'CREATE PROCEDURE dbo.mspLogPOAction'
GO


CREATE PROCEDURE dbo.mspLogPOAction
(
	@User			bVPUserName 
,  @ActionInt	SMALLINT
,	@Version		VARCHAR(7)
,	@JCCo    bCompany
,  @POFrom	VARCHAR(30)
,  @POTo		VARCHAR(30)
,	@DateFrom	bMonth = null
,	@DateTo		bMonth = null
,	@Details    VARCHAR(50)
,	@ErrorTxt	VARCHAR(255)
)
AS
/* ========================================================================
	Object Name: dbo.mspLogPOAction
	Author:		 Gurdian, Leo
	Created:		 1.22.18
	Modified:	 1.31.18
	Description: Procedure to populate the PO log table.
	Update Hist: 
	L.Gurdian   1.22.18  initial
					1.31.18	add order date range
					2.09.18	add 'REFRESH' to support refreshing of existing, peviously pulled, edited POs
	========================================================================
*/
DECLARE @Action AS VARCHAR(20)
	, @ActionDate AS DATETIME 

SET @Action = CASE @ActionInt
				WHEN 0 THEN 'REPORT'
				WHEN 1 THEN 'REFRESH'
            WHEN 2 THEN 'COPY OFFLINE'
				WHEN 3 THEN 'EMAIL'
				WHEN 4 THEN 'INVALID USER'
				WHEN 5 THEN 'ERROR'
				ELSE 'UNKNOWN' 
		END

SET @ActionDate = SYSDATETIME();

BEGIN
	INSERT INTO dbo.mckPOLog (VPUserName, DateTime, Version, JCCo, POFrom, POTo, DateFrom, DateTo, Action, Details, ErrorText)
		VALUES (@User, @ActionDate, @Version, @JCCo, @POFrom, @POTo, @DateFrom, @DateTo, @Action, @Details, @ErrorTxt)
END



GO


Grant EXECUTE ON dbo.mspLogPOAction TO [MCKINSTRY\Viewpoint Users]