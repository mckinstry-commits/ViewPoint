SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [dbo].[vspPRCanadaROEPurge]
/***********************************************************
* CREATED BY: MV	03/14/2013  PR ROE Purge
* Modified:  
*
* USAGE:
* Purges T-4 info for a given tax year.  
* Includes vPRROEEmployeeHistory, vPRROEEmployeeInsurEarningsPPD, vPRROEEmployeeSSPayments, 
*
* INPUT PARAMETERS
*   @PRCo		PR Company
*   @ROEDate	ROE date to purge
*
* OUTPUT PARAMETERS
*   @errmsg     if something went wrong
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/
(@PRCo bCompany, @ROEDate bDate, @ErrMsg varchar(4000) output)
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @rcode int
	SELECT @rcode = 0

	IF EXISTS
		(
			SELECT * 
			FROM dbo.vPRROEEmployeeHistory
			WHERE PRCo=@PRCo AND ROEDate=@ROEDate
		)
	BEGIN
		BEGIN TRY
			BEGIN TRAN
				-- Delete ROE history 
				DELETE FROM dbo.vPRROEEmployeeSSPayments WHERE PRCo=@PRCo AND ROEDate = @ROEDate
				DELETE FROM dbo.vPRROEEmployeeInsurEarningsPPD WHERE PRCo=@PRCo AND ROEDate = @ROEDate
				DELETE FROM dbo.vPRROEEmployeeHistory WHERE PRCo=@PRCo AND ROEDate = @ROEDate
			-- Success
			COMMIT TRAN
		END TRY
		BEGIN CATCH
			SET @ErrMsg = ERROR_MESSAGE()
			IF @@TRANCOUNT > 0 BEGIN ROLLBACK TRAN END
			RAISERROR (@ErrMsg, 15, 1)
		END CATCH
	END
	ELSE
	BEGIN
		SELECT @rcode = 1
		RETURN @rcode
	END

END


GO
GRANT EXECUTE ON  [dbo].[vspPRCanadaROEPurge] TO [public]
GO
