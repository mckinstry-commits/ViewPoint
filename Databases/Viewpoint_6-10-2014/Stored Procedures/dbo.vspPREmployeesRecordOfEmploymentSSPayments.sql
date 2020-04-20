SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspPREmployeesRecordOfEmploymentSSPayments]
/************************************************************************
* CREATED:	CHS 04/02/2013   
* MODIFIED: CHS 05/06/2013 changed datatype to string
*
* Purpose of Stored Procedure
*
*    Return employee data from the ROE SS Payments history table as record set (table[2])    
*           
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/
(@PRCo bCompany,
    @Employee bEmployee,
	@ROEDate bDate)

AS
BEGIN
	SET NOCOUNT ON

	IF @Employee = 0
		BEGIN
		SELECT @Employee = NULL
		END

  SELECT PRCo, Employee, ROEDate, Category, Number, StatutoryHolidayPaymentDate, OtherMoniesCode,   
   SpecialPaymentStartDate, SpecialPaymentCode, SpecialPaymentPeriod, Amount  
  FROM dbo.PRROEEmployeeSSPayments  
  WHERE PRCo = @PRCo   
   AND Employee = ISNULL(@Employee, Employee)  
   AND ROEDate = ISNULL(@ROEDate, ROEDate)  
  ORDER BY Employee ASC, Category ASC 

  
 RETURN 0  

END
GO
GRANT EXECUTE ON  [dbo].[vspPREmployeesRecordOfEmploymentSSPayments] TO [public]
GO
