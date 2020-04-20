SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.vspPRCanadaT4Purge    Script Date: 11/02/2010 3:22:39 PM ******/
CREATE procedure [dbo].[vspPRCanadaT4Purge]
/***********************************************************
* CREATED BY: Liz S 11/02/2010
* Modified:  
*
* USAGE:
* Purges T-4 info for a given tax year.  
* Includes bPRCAEmployeeCodes, bPRCAEmployeeItems, bPRCAEmployeeProvince, 
*		   bPRCAEmployees, bPRCAEmployerCodes, bPRCAEmployerItems, bPRCAEmployerProvince,
*		   bPRCAEmployer, bPRCACodes, bPRCAItems
*
* INPUT PARAMETERS
*   @PRCo		PR Company
*   @TaxYear	Tax Year to purge
*
* OUTPUT PARAMETERS
*   @errmsg     if something went wrong
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/
(@PRCo bCompany, @TaxYear char(4), @ErrMsg varchar(4000) output)
AS
BEGIN
	SET NOCOUNT ON

	BEGIN TRY
		BEGIN TRAN

			-- Delete Employee T4 Information
			DELETE FROM dbo.bPRCAEmployeeCodes WHERE PRCo=@PRCo AND TaxYear = @TaxYear
			DELETE FROM dbo.bPRCAEmployeeItems WHERE PRCo=@PRCo AND TaxYear = @TaxYear
			DELETE FROM dbo.bPRCAEmployeeProvince WHERE PRCo=@PRCo AND TaxYear = @TaxYear
			DELETE FROM dbo.bPRCAEmployees WHERE PRCo=@PRCo AND TaxYear = @TaxYear
			
			-- Delete Employer T4 Information
			DELETE FROM dbo.bPRCAEmployerCodes WHERE PRCo=@PRCo AND TaxYear = @TaxYear
			DELETE FROM dbo.bPRCAEmployerItems WHERE PRCo=@PRCo AND TaxYear = @TaxYear
			DELETE FROM dbo.bPRCAEmployerProvince WHERE PRCo=@PRCo AND TaxYear = @TaxYear
			DELETE FROM dbo.bPRCAEmployer WHERE PRCo=@PRCo AND TaxYear = @TaxYear

			-- Delete T4 Items and Codes setup for the given year and PR Company
			DELETE FROM dbo.bPRCACodes WHERE PRCo=@PRCo AND TaxYear = @TaxYear
			DELETE FROM dbo.bPRCAItems WHERE PRCo=@PRCo AND TaxYear = @TaxYear
			
		-- Success
		COMMIT TRAN
	END TRY
	BEGIN CATCH
		SET @ErrMsg = ERROR_MESSAGE()
		IF @@TRANCOUNT > 0 BEGIN ROLLBACK TRAN END
		RAISERROR (@ErrMsg, 15, 1)
	END CATCH


END


GO
GRANT EXECUTE ON  [dbo].[vspPRCanadaT4Purge] TO [public]
GO
