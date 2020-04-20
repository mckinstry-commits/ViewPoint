SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspHQPRFederalW2Export]
/************************************************************************
* CREATED:    
* MODIFIED:	MH 11/22/2008 - Corrected column alias to be consistant with
*							State/Local exports. 
*			EN 10/29/2012 - D-05285/#146601 Removed c.Method (CoMethod) from the select list   
*
* Purpose of Stored Procedure
*
*	Return data used to export W2 info into electronic EFW2 file
*    
*           
* Notes about Stored Procedure
* 
*
* returns 0 if successfull 
* returns 1 and error msg if failed
*
*************************************************************************/

    (@prco bCompany, @taxyear varchar(4))

as
set nocount on

	select distinct(a.Employee) 
	from PRWA a 
	LEFT JOIN PRWH c ON a.PRCo = c.PRCo and a.TaxYear = c.TaxYear
	LEFT JOIN PRWE b ON a.PRCo = b.PRCo and a.TaxYear = b.TaxYear and a.Employee = b.Employee
	where a.PRCo = @prco and a.TaxYear = @taxyear
	ORDER BY a.Employee

	Select a.PRCo, a.TaxYear, a.Employee, a.Item, 'Amount'=Round(a.Amount, 2, 1),
		   b.SSN, b.FirstName, b.MidName, b.LastName, b.Suffix, b.LocAddress 'EmpLocAddress', b.DelAddress 'EmpDelAddress',
		   b.City 'EmpCity', b.State 'EmpState', b.Zip 'EmpZip', b.ZipExt 'EmpZipExt', b.Statutory, b.Deceased, b.PensionPlan,
		   b.CivilStatus, b.SpouseSSN, b.ThirdPartySickPay,
		   c.EIN, c.PIN, c.Resub, c.ResubTLCN, c.CoName, c.LocAddress 'CoLocAddress', c.DelAddress 'CoDelAddress', c.City 'CoCity',
		   c.State 'CoState', c.Zip 'CoZip', c.ZipExt 'CoZipExt', c.Contact 'CoContact', c.Phone 'CoPhone', c.PhoneExt 'CoPhoneExt', 
		   c.EMail 'CoEMail', c.Fax 'CoFax', c.SickPayFlag 'CoSickPay'
	from PRWA a 
	LEFT JOIN PRWH c ON a.PRCo = c.PRCo and a.TaxYear = c.TaxYear
	LEFT JOIN PRWE b ON a.PRCo = b.PRCo and a.TaxYear = b.TaxYear and a.Employee = b.Employee
	where a.PRCo = @prco and a.TaxYear = @taxyear
	ORDER BY a.PRCo, a.TaxYear, a.Employee, a.Item

GO
GRANT EXECUTE ON  [dbo].[vspHQPRFederalW2Export] TO [public]
GO
