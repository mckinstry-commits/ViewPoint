SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Lane Gresham>
-- Create date: <01-18-11>
-- Modified 05/12/11 - Mark H.  Split up the validation.  First check employee is a technician then return their name.
-- Assumption is a Tech must be a valid PR Employee.  Previous validation in TC entry will have already verified the
-- Employee exists in PREH.
-- Description:	<Validation for the SM company selected for a given employee>
-- =============================================
CREATE PROCEDURE [dbo].[vspPRSMCompanyVal]
	@PRCo bCompany, @SMCo bCompany, @Employee bEmployee, @Type char(1), @msg varchar(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    
    IF @Type = 'S'
    BEGIN
		DECLARE @IsValidSMCo bit
		EXEC @IsValidSMCo = dbo.vspSMCoVal @SMCo = @SMCo, @msg = @msg OUTPUT
    
		IF @IsValidSMCo = 1
		BEGIN 
			RETURN 1
		END

		--First we need to check that the Employee is set up as a Technician
		IF NOT EXISTS(SELECT 1 FROM SMTechnician WHERE SMCo = @SMCo and PRCo = @PRCo and Employee = @Employee)
		BEGIN
			SET @msg = 'Employee is not setup as a Technician in SM' 
			RETURN 1
		END
		
		--If employee exists as a Technician return their name.
		SELECT @msg = PREHName.FullName 
		FROM PREHName
		WHERE PREHName.PRCo = @PRCo and PREHName.Employee = @Employee
	END
	
	RETURN 0
	
END



GO
GRANT EXECUTE ON  [dbo].[vspPRSMCompanyVal] TO [public]
GO
