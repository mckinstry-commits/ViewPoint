SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspPREmployeesRecordOfEmployment]
/************************************************************************
* CREATED:	CHS 02/28/2013   
* MODIFIED: CHS 04/02/2013 Normalized into called procedures.
*			CHS 05/06/2013 changed datatype to string
*
* Purpose of Stored Procedure
*
*    Return employee data from the ROE History table as record set (table[0])
*    Return employee data from the ROE InsurEarningsPPD history table as record set (table[1])
*    Return employee data from the ROE SS Payments history table as record set (table[2])    
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
	@AmendDate bDate,
	@msg varchar(255) = '' output)

AS
BEGIN
	SET NOCOUNT ON

	-- validate required field
	IF EXISTS (SELECT 1 FROM dbo.HQCO WHERE HQCo = @PRCo AND ISNULL(FedTaxId, '') = '')
		BEGIN
		SELECT @msg = 'The Account Number (CRA Business Number) is missing from HQ Company. Per Service Canada, an ROE must include Canada Revenue Agency Number.'
		RETURN 5
		END
	
	-- we must have records in PRROEEmployeeInsurEarningsPPD table
	IF @AmendedROE ='Y'
		BEGIN
		IF EXISTS(SELECT Top 1 1 FROM PRROEEmployeeHistory h
						Left JOIN PRROEEmployeeInsurEarningsPPD i ON h.PRCo = i.PRCo AND h.Employee = i.Employee AND h.ROEDate = i.ROEDate
					WHERE h.PRCo = @PRCo 
						AND h.Employee = ISNULL(@Employee, h.Employee)  
						AND i.InsurableEarnings IS NULL
						AND (h.AmendedDate = @AmendDate)
						)
			BEGIN
			SELECT @msg = 'One or more Employees are missing Insurable Earnings information. Per Service Canada, an ROE must include Insurable Earnings information to be valid.'
			RETURN 5
			END
		END

	ELSE
		BEGIN
		IF EXISTS(SELECT Top 1 1 FROM PRROEEmployeeHistory h
						Left JOIN PRROEEmployeeInsurEarningsPPD i ON h.PRCo = i.PRCo AND h.Employee = i.Employee AND h.ROEDate = i.ROEDate
					WHERE h.PRCo = @PRCo 
						AND h.Employee = ISNULL(@Employee, h.Employee)  
						AND i.InsurableEarnings IS NULL
						AND (h.ROEDate = @ROEDate)
						)
			BEGIN
			SELECT @msg = 'One or more Employees are missing Insurable Earnings information. Per Service Canada, an ROE must include Insurable Earnings information to be valid.'
			RETURN 5
			END

		END
		
 
	EXECUTE vspPREmployeesRecordOfEmploymentHistory @PRCo, @Employee, @ROEDate,  @AmendedROE,  @AmendDate
	
	EXECUTE vspPREmployeesRecordOfEmploymentInsurEarningsPPD @PRCo, @Employee, @ROEDate

	EXECUTE vspPREmployeesRecordOfEmploymentSSPayments @PRCo, @Employee, @ROEDate

  
 RETURN 0  

END
GO
GRANT EXECUTE ON  [dbo].[vspPREmployeesRecordOfEmployment] TO [public]
GO
