SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspPRROEHistoryFirstDayLastDayVal]
/************************************************************************
* CREATED:	MV	05/02/2013 TFS-46562 - validate First Day Paid/Last Day Paid    
* MODIFIED:	

*
* Purpose of Stored Procedure
*
*    Validate and prevent duplication of entries with same First Day Worked/Last Day Paid dates.
*	 These dates default from Employee Master and represent a unique record-of-employment period.    
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
	@FirstDayWorked bDate,
	@LastDayPaid bDate,
	@msg varchar(255) = '' output)

AS
BEGIN
	SET NOCOUNT ON

    DECLARE @returnCode INT
    SELECT @returnCode = 0

	IF EXISTS
			(
				SELECT 1 
				FROM dbo.vPRROEEmployeeHistory 
				WHERE Employee = @Employee 
				AND FirstDayWorked = ISNULL(@FirstDayWorked,'1/1/2078') 
				AND LastDayPaid = ISNULL(@LastDayPaid,'1/1/2078') 
				AND ROEDate <> ISNULL(@ROEDate, '1/1/2078'))
		BEGIN
		SELECT
			@returnCode = 1, 
			@msg = 'This employee has already been entered with the same ''First Day Worked'' and ''Last Day Paid'' date pair.'

			RETURN @returnCode
		END

	RETURN @returnCode
END


GO
GRANT EXECUTE ON  [dbo].[vspPRROEHistoryFirstDayLastDayVal] TO [public]
GO
