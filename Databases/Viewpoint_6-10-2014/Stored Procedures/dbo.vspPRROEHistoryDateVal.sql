SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspPRROEHistoryDateVal]
/************************************************************************
* CREATED:	CHS 02/15/2013   
* MODIFIED:	MV	05/01/2013 TFS-46562 - changed err msg on RecentRehire/RecentSeparation validation

*
* Purpose of Stored Procedure
*
*    validate and prevent duplication of entries.
*    
*           
* Notes about Stored Procedure
* 
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/
(@PRCo bCompany, 
    @Employee bEmployee, 
	@ROEDate bDate,
	@msg varchar(255) = '' output)

AS
BEGIN
	SET NOCOUNT ON

    DECLARE @returnCode INT
    SELECT @returnCode = 0

	DECLARE 	@RecentRehireDate bDate, @RecentSeparationDate bDate

	SELECT	
		@RecentRehireDate = RecentRehireDate,
		@RecentSeparationDate = RecentSeparationDate
	FROM PREH 
	WHERE PRCo = @PRCo AND Employee = @Employee

	IF EXISTS
			(
				SELECT 1 
				FROM dbo.vPRROEEmployeeHistory 
				WHERE Employee = @Employee 
				AND FirstDayWorked = @RecentRehireDate 
				AND LastDayPaid = @RecentSeparationDate 
				AND ROEDate <> ISNULL(@ROEDate, '1/1/2078'))
		BEGIN
		SELECT
			@returnCode = 1, 
			--@msg = 'This employee has already been entered with a different ROE Date.'
			@msg = 'This employee has already been entered with the same ''Most Recent Rehire Date'' and ''Most Recent Separation Date'' pair.'

			RETURN @returnCode
		END

	RETURN @returnCode
END


GO
GRANT EXECUTE ON  [dbo].[vspPRROEHistoryDateVal] TO [public]
GO
