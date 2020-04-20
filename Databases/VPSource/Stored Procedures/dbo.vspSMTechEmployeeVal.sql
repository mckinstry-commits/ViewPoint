SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
	CREATE  PROCEDURE [dbo].[vspSMTechEmployeeVal]
	/******************************************************
	* CREATED BY: 
	* MODIFIED By: 
	*
	* Usage:
	*	
	*
	* Input params:
	*	
	*	
	*
	* Output params:
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	@SMCo bCompany, @Technician varchar(15), @PRCo bCompany, @EmpSortName varchar(15), @Employee bEmployee OUTPUT, @msg varchar(100) OUTPUT
   	
AS
BEGIN
	SET NOCOUNT ON

	DECLARE @empvalrcode TINYINT
 	   	
	EXEC @empvalrcode = dbo.bspPREmplValName @prco = @PRCo, @empl = @EmpSortName, @activeopt = 'X', @emplout = @Employee OUTPUT, @msg = @msg OUTPUT
	
	IF @empvalrcode = 0
	BEGIN
		IF EXISTS(SELECT 1 FROM SMTechnician WHERE SMCo = @SMCo AND Technician <> @Technician AND PRCo = @PRCo AND Employee = @Employee)
		BEGIN
			SET @msg = 'Employee is currently assigned to Technician - ' + (SELECT Technician FROM dbo.SMTechnician WHERE SMCo = @SMCo AND PRCo = @PRCo AND Employee = @Employee)
			RETURN 1
		END
	END
	ELSE
	BEGIN
		--Employee not found. Allow the error message from bspPREmplValName to show.
		RETURN 1
	END

	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMTechEmployeeVal] TO [public]
GO
