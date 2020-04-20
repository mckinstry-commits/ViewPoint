SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[vrvPREmployeesRecordOfEmploymentHistory]
/************************************************************************
* CREATED:	DML 09 April 2013  
* MODIFIED: 
*
* Purpose of View:
* Return employee data from the ROE History table for ROE Report
*           
*
*************************************************************************/
as
SELECT 
h.PRCo
, h.Employee
, h.ROEDate
, AmendedDate
, ROE_SN
, SIN
, FirstName
, MiddleInitial
, LastName
, AddressLine1
, AddressLine2
, AddressLine3
, EmployeeOccupation
, FirstDayWorked
, LastDayPaid
, FinalPayPeriodEndDate
, ExpectedRecallCode
, ExpectedRecallDate
, TotalInsurableHours
, TotalInsurableEarnings
, ReasonForROE
, ContactFirstName
, ContactLastName
, ContactAreaCode
, ContactPhoneNbr
, ContactPhoneExt
, Comments
, PayPeriodType
, s.VacationSum
, Language
, c.FedTaxId
, c.HQCo
, c.Name as EmployerName
, c.Address as EmployerAddr
, c.Address2 as EmployerAddr2
, c.City as EmployerCity
, c.State as EmployerState
, c.Zip as EmployerZip 
	FROM PRROEEmployeeHistory h  
	   LEFT JOIN HQCO c ON h.PRCo = c.HQCo  
	   LEFT JOIN (SELECT p.PRCo, p.Employee, p.ROEDate, SUM(p.Amount) as 'VacationSum'   
		  FROM dbo.PRROEEmployeeSSPayments p   
WHERE p.Category = 'V'  
		  GROUP BY p.PRCo, p.Employee, p.ROEDate, p.Amount)s  		  
	ON s.PRCo = h.PRCo AND s.Employee = h.Employee AND s.ROEDate = h.ROEDate  
	

  

     
GO
GRANT SELECT ON  [dbo].[vrvPREmployeesRecordOfEmploymentHistory] TO [public]
GRANT INSERT ON  [dbo].[vrvPREmployeesRecordOfEmploymentHistory] TO [public]
GRANT DELETE ON  [dbo].[vrvPREmployeesRecordOfEmploymentHistory] TO [public]
GRANT UPDATE ON  [dbo].[vrvPREmployeesRecordOfEmploymentHistory] TO [public]
GRANT SELECT ON  [dbo].[vrvPREmployeesRecordOfEmploymentHistory] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvPREmployeesRecordOfEmploymentHistory] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvPREmployeesRecordOfEmploymentHistory] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvPREmployeesRecordOfEmploymentHistory] TO [Viewpoint]
GO
