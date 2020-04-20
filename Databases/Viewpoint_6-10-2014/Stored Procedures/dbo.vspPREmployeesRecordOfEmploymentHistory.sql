SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspPREmployeesRecordOfEmploymentHistory]
/************************************************************************
* CREATED:	CHS 04/02/2013  
* MODIFIED: CHS 05/06/2013 changed datatype to string
*
* Purpose of Stored Procedure
*
*    Return employee data from the ROE History table as record set (table[0]) 
*           
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/
(@PRCo bCompany,
    @Employee bEmployee, 
    @ROEDate bDate,
    @AmendedROE bYN,
    @AmendDate bDate)

AS
BEGIN
	SET NOCOUNT ON
	

	IF @Employee = 0
		BEGIN
		SELECT @Employee = NULL
		END
	

	SELECT h.PRCo, h.Employee, h.ROEDate, ROE_SN, SIN, FirstName, MiddleInitial, LastName, AddressLine1, AddressLine2, AddressLine3,  
			EmployeeOccupation, FirstDayWorked, LastDayPaid, FinalPayPeriodEndDate, ExpectedRecallCode, ExpectedRecallDate,   
			TotalInsurableHours, TotalInsurableEarnings, ReasonForROE, ContactFirstName, ContactLastName, ContactAreaCode,  
			ContactPhoneNbr, ContactPhoneExt, Comments, AmendedDate, PayPeriodType, s.VacationSum, Language, c.FedTaxId,   
			c.HQCo, c.Name as EmployerName, c.Address as EmployerAddr, c.Address2 as EmployerAddr2, c.City as EmployerCity, 
			c.State as    EmployerState, c.Zip as EmployerZip  
	FROM dbo.PRROEEmployeeHistory h  
	   LEFT JOIN dbo.HQCO c ON h.PRCo = c.HQCo  
	   LEFT JOIN (SELECT p.PRCo, p.Employee, p.ROEDate, SUM(p.Amount) as 'VacationSum'   
		  FROM dbo.PRROEEmployeeSSPayments p   
		  WHERE p.PRCo = @PRCo AND p.Employee = ISNULL(@Employee, p.Employee) AND p.ROEDate = ISNULL(@ROEDate, p.ROEDate) AND p.Category = 'V'  
		  GROUP BY p.PRCo, p.Employee, p.ROEDate, p.Amount)s   
     
	ON s.PRCo = h.PRCo AND s.Employee = h.Employee AND s.ROEDate = h.ROEDate  
	WHERE h.PRCo = @PRCo   
	   AND h.Employee = ISNULL(@Employee, h.Employee)  
	   AND ((h.ROEDate = ISNULL(@ROEDate, h.ROEDate) AND @AmendedROE ='N') OR (AmendedDate = @AmendDate AND @AmendedROE ='Y'))    
	ORDER BY Employee ASC  
  

 RETURN 0  

END
GO
GRANT EXECUTE ON  [dbo].[vspPREmployeesRecordOfEmploymentHistory] TO [public]
GO
