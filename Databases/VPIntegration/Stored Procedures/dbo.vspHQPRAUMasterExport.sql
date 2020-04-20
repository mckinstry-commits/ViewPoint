SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspHQPRAUMasterExport]
/************************************************************************
* CREATED: EN 4/16/2011    
* MODIFIED:	
*
* Purpose of Stored Procedure
*
*	Return supplier/payer data used to export PAYG info for specified PR Company/Tax Year into electronic file.
*
* Data required for return:
*			PayerABN
*			PayerCompanyName
*			PayerAddress
*			PayerAddress2
*			PayerCity
*			PayerState
*			PayerPostalCode
*			PayerContactName (ContactGivenName + ' ' + ContactGivenName2 + ' ' + ContactSurname)
*			PayerContactPhone
*			PayerContactEmail
*			PayerContactFax
*			ReportEndDate
*			BranchNumber
*************************************************************************/

    (@PRCo bCompany, @TaxYear varchar(4))

AS
SET NOCOUNT ON


SELECT	EmployerMaster.ABN AS [PayerABN],
		EmployerMaster.CompanyName AS [PayerCompanyName],
		EmployerMaster.Address AS [PayerAddress],
		EmployerMaster.Address2 AS [PayerAddress2],
		EmployerMaster.City AS [PayerCity],
		EmployerMaster.State AS [PayerState],
		EmployerMaster.PostalCode AS [PayerPostalCode],
		EmployerMaster.ContactGivenName + ' ' + EmployerMaster.ContactGivenName2 + ' ' + EmployerMaster.ContactSurname 
			AS [PayerContactName],
		EmployerMaster.ContactPhone AS [PayerContactPhone],
		EmployerMaster.ContactEmail AS [PayerContactEmail],

		Employer.ContactFax AS [PayerContactFax],
		Employer.EndDate AS [ReportEndDate],
		Employer.BranchNumber
		
FROM PRAUEmployerMaster EmployerMaster
JOIN PRAUEmployer Employer
	ON Employer.PRCo = EmployerMaster.PRCo AND Employer.TaxYear = EmployerMaster.TaxYear 
WHERE EmployerMaster.PRCo = @PRCo AND EmployerMaster.TaxYear = @TaxYear 

GO
GRANT EXECUTE ON  [dbo].[vspHQPRAUMasterExport] TO [public]
GO
