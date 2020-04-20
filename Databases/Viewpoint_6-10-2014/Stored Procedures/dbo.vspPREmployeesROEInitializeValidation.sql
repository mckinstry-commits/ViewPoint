SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspPREmployeesROEInitializeValidation]
/************************************************************************
* CREATED:	CHS 03/15/2013   
* MODIFIED:
*
* Purpose of Stored Procedure
*
*    Validate that the Employee is not already listed in the history table.  
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/
(@PRCo bCompany, @msg varchar(255) = '' output)

AS
BEGIN
	SET NOCOUNT ON

		DECLARE @MyRowCount int

		SELECT 1 FROM dbo.PRROEEmployeeHistory h 
					INNER JOIN dbo.PRROEEmployeeWorkfile w on h.PRCo = w.PRCo 
															AND h.Employee = w.Employee 
															AND h.ROEDate = w.ROEDate
				WHERE  w.PRCo = @PRCo AND w.ProcessYN = 'Y' AND w.VPUserName = SYSTEM_USER
	
		SELECT @MyRowCount = @@ROWCOUNT

		IF @MyRowCount > 0 
			BEGIN
			SELECT @msg = cast(@MyRowCount as varchar(20))
			RETURN 1
			END

	RETURN 0

END
GO
GRANT EXECUTE ON  [dbo].[vspPREmployeesROEInitializeValidation] TO [public]
GO
