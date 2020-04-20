SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

IF EXISTS (SELECT * FROM dbo.sysobjects WHERE id = object_id(N'[dbo].[mckspHQBCAdd]') AND OBJECTPROPERTY(id, N'IsProcedure') = 1)
DROP PROCEDURE [dbo].[mckspHQBCAdd]
GO

-- **************************************************************
--  PURPOSE: Adds new HQBC record
--    INPUT: Values list (see below)
--   RETURN: ErrCode (0 if successful, 1 if not)
--   AUTHOR: Brian Gannon-McKinley
--  -------------------------------------------------------------
--  HISTORY:
--    05/20/2014  Created stored procedure
--    05/27/2014  Tested stored procedure
-- **************************************************************

CREATE PROCEDURE [dbo].[mckspHQBCAdd]
	@Company [dbo].[bCompany]
	,@UIMonth smalldatetime
	,@UserAccount varchar(128)
	,@Notes varchar(max)
	,@BatchId [dbo].[bBatchID] OUTPUT

AS

SET NOCOUNT ON

DECLARE  @rcode int, 
	@Source [dbo].[bSource], @TableName [char](20), @BatchTableName char(20), @DateCreated datetime, @InUseBy [dbo].[bVPUserName], @Status tinyint, @Rstrict [dbo].[bYN],
	@Adjust [dbo].[bYN], @PRGroup [dbo].[bGroup], @PREndDate [dbo].[bDate], @DatePosted [dbo].[bDate], @DateClosed smalldatetime, @ErrorMessage varchar(60)

----------------------------------------------
-- Set HQBC Variables
----------------------------------------------

SELECT	@rcode = -1
		,@Source = 'AR Receipt'
		,@TableName = 'bHQBC'
		,@BatchTableName = 'ARBH'
		,@DateCreated = GetDate()
		,@InUseBy = NULL
		,@Status = 0
		,@Rstrict = 'N'
		,@Adjust = 'N'
		,@PRGroup = NULL
		,@PREndDate = NULL
		,@DatePosted = NULL
		,@DateClosed = NULL

EXECUTE @BatchId = [dbo].[bspHQTCNextTrans] @TableName, @Company, @UIMonth, @ErrorMessage OUTPUT

----------------------------
-- Save The Record
----------------------------
BEGIN TRY
BEGIN TRANSACTION Trans_addHQBC

INSERT INTO [dbo].[bHQBC] (
	 Co
	,Mth
	,BatchId
	,Source
	,TableName
	,InUseBy
	,DateCreated
	,CreatedBy
	,Status
	,Rstrict
	,Adjust
	,PRGroup
	,PREndDate
	,DatePosted
	,DateClosed
	,Notes
	)
VALUES (
	@Company
	,@UIMonth
	,@BatchId
	,@Source
	,@BatchTableName
	,@InUseBy
	,@DateCreated
	,@UserAccount
	,@Status
	,@Rstrict
	,@Adjust
	,@PRGroup
	,@PREndDate
	,@DatePosted
	,@DateClosed
	,@Notes
	)

COMMIT TRANSACTION Trans_addHQBC
SELECT @rcode=0

END TRY

BEGIN CATCH
	ROLLBACK TRANSACTION Trans_addHQBC
	SELECT @rcode=1
END CATCH

ExitProc:
RETURN(@rcode)

SET QUOTED_IDENTIFIER OFF 
GO

SET ANSI_NULLS ON 
GO