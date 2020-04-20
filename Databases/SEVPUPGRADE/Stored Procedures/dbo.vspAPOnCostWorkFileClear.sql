SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspAPOnCostWorkFileClear]
/***************************************************
* CREATED BY:	CHS	03/13/2012
*
* Usage:
*   Clears AP WorkFile Header and Detail tables.
*
* Input:
*	@APCo         
*	@UserID
*
* Output:
*	@msg          header description
*
* Returns:
*	0             success
*   1             error
*************************************************/
(@APCo bCompany = null, @UserID bVPUserName = null, @Msg varchar(60) output)
   	
	AS
   
	SET NOCOUNT ON
   
	DECLARE @RCode int
   
	SELECT @RCode = 0


	IF @APCo is null
		BEGIN
		SELECT @Msg = 'Missing AP Company', @RCode = 1
		RETURN @RCode
		END

	IF @UserID is null
		BEGIN
		SELECT @Msg = 'Missing User Name', @RCode = 1
		RETURN @RCode
		END

	BEGIN TRY
		DELETE vAPOnCostWorkFileDetail WHERE APCo=@APCo and UserID = @UserID
	END TRY

	BEGIN CATCH
		SELECT @Msg = 'An error was encountered deleting records from APOnCostWorkFileDetail, Company: ' + cast(@APCo as varchar(10)) + '  and User ID: ' + cast(@UserID as varchar(20)), @RCode = 1
		RETURN @RCode
	END CATCH

	BEGIN TRY
		DELETE vAPOnCostWorkFileHeader WHERE APCo=@APCo and UserID = @UserID
	END TRY

	BEGIN CATCH
		SELECT @Msg = 'An error was encountered deleting records from APOnCostWorkFileHeader, Company: ' + cast(@APCo as varchar(10)) + '  and User ID: ' + cast(@UserID as varchar(20)), @RCode = 1
		RETURN @RCode
	END CATCH

	IF NOT EXISTS(SELECT TOP 1 1 FROM vAPOnCostWorkFileHeader WHERE APCo=@APCo and UserID = @UserID)
		BEGIN
		SELECT @Msg = 'On-Cost WorkFile records were successfully cleared.', @RCode = 0
		RETURN @RCode
		END
		
	ELSE
		BEGIN
		SELECT @Msg = 'On-Cost WorkFile records were not successfully cleared.', @RCode = 1
		RETURN @RCode
		END		
	

	RETURN @RCode
GO
GRANT EXECUTE ON  [dbo].[vspAPOnCostWorkFileClear] TO [public]
GO
