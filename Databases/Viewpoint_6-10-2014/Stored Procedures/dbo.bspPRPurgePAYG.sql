SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRPurgePAYG   Script Date: 8/28/99 9:35:39 AM ******/
CREATE procedure [dbo].[bspPRPurgePAYG]
/***********************************************************
* CREATED BY:	CHS	#142027 - 3/31/2011
* Modified: 	CHS	#142027 - 4/14/2011
*			
* USAGE:
* Purges Header, & ETP Employee Amounts for a given tax year and Company from the 
* tables PRAUEmployeeETPAmounts, & vPRAUEmployerETP
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
*GRANT EXECUTE ON bspPRPurgePAYG TO public;
*****************************************************/
(@PRCo bCompany, 
	@TaxYear char(4),
	@Employee bEmployee,
	@Msg varchar(255) output)
	
	AS

	SET NOCOUNT ON

	DECLARE @rcode int
	SELECT @rcode = 1, @Msg = 'Purge of PAYG data unsuccessful.'
	
	IF ISNULL(@TaxYear, '') = ''
		BEGIN
		SELECT @rcode = 1, @Msg = 'Tax year was not provided.'	
		RETURN @rcode
		END
		
	-- delete only one employee if provided.
	IF ISNULL(@Employee, 0) = 0
		BEGIN
		DELETE FROM PRAUEmployeeMiscItemAmounts WHERE PRCo=@PRCo and TaxYear = @TaxYear
		DELETE FROM PRAUEmployeeItemAmounts WHERE PRCo=@PRCo and TaxYear = @TaxYear		
		DELETE FROM PRAUEmployees WHERE PRCo=@PRCo and TaxYear = @TaxYear
		END
		
	ELSE		
		BEGIN
		DELETE FROM PRAUEmployeeMiscItemAmounts WHERE PRCo=@PRCo and TaxYear = @TaxYear AND @Employee = Employee
		DELETE FROM PRAUEmployeeItemAmounts WHERE PRCo=@PRCo and TaxYear = @TaxYear AND @Employee = Employee		
		DELETE FROM PRAUEmployees WHERE PRCo=@PRCo and TaxYear = @TaxYear AND @Employee = Employee
		END
		
	-- if an employee is specified, we could have scenario where other employees have not been
	-- purged, in which case we do not want to attempt to purge from the parent table.	
	IF ISNULL(@Employee, 0) <> 0
		BEGIN
		SELECT @rcode = 0, @Msg =  'Successfully purged Employee PAYG data for Company ' + CAST(@PRCo as VARCHAR(60)) + ' and Tax Year ' + @TaxYear + ' and Employee ' + CAST(@Employee as VARCHAR(10)) + '. '		
		END
		
	ELSE
		BEGIN
		DELETE FROM PRAUEmployerSuperItems WHERE PRCo=@PRCo and TaxYear = @TaxYear		
		DELETE FROM PRAUEmployerATOItems WHERE PRCo=@PRCo and TaxYear = @TaxYear
		DELETE FROM PRAUEmployerMiscItems WHERE PRCo=@PRCo and TaxYear = @TaxYear
		DELETE FROM PRAUEmployer WHERE PRCo=@PRCo and TaxYear = @TaxYear
		SELECT @rcode = 0, @Msg =  'Successfully purged PAYG data for Company ' + CAST(@PRCo as VARCHAR(60)) + ' and Tax Year ' + @TaxYear + '. '
		END
	   
	bspexit:
	RETURN @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRPurgePAYG] TO [public]
GO
