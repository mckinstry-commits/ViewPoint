SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 8/16/10
-- Modified:  MarkH 8/25/10 - Added @Rate output to vspSMTechnicianVal
-- Description:	Technician Validation for the technician form
-- =============================================
CREATE PROCEDURE [dbo].[vspSMTechnicianFormTechnicianVal]
	@SMCo bCompany, @Technician varchar(15), @PRCo bCompany OUTPUT, @Employee varchar(15) OUTPUT, @msg varchar(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @TechnicianNotFound bit

	EXEC @TechnicianNotFound = dbo.vspSMTechnicianVal @SMCo = @SMCo, @Technician = @Technician, @msg = @msg OUTPUT
	
	--Here is where we start looking to do some defaulting behavior
	--based on finding an employee with a given sort name
	IF @TechnicianNotFound = 1
	BEGIN
		DECLARE @EmployeeNotFound bit, @EmployeeName varchar(60)

		--Get the SMCo's PRCo for defaulting
		EXEC dbo.vspSMCoVal @SMCo = @SMCo, @PRCo = @PRCo OUTPUT

		--Attempt to find an employee with the same employee id or sortname and return for defaulting the employee field
		EXEC @EmployeeNotFound = dbo.bspPREmplValName @prco = @PRCo, @empl = @Technician, @activeopt = 'Y', @emplout = @Employee OUTPUT, @msg = @EmployeeName OUTPUT
		
		--Set the default employee to null if no employee was found in the PR Employee validation or if we already have the
		--employee tied to a technician record for the current SMCo
		IF @EmployeeNotFound = 1 OR EXISTS(SELECT 1 FROM SMTechnician WHERE SMCo = @SMCo AND PRCo = @PRCo AND Employee = @Employee)
		BEGIN
			SET @Employee = NULL
		END
		ELSE
		BEGIN
			--Otherwise an employee was found that hasn't been tied to a technician and we should return their name to the description label
			SET @msg = @EmployeeName
		END
	END
	
	RETURN 0
END



GO
GRANT EXECUTE ON  [dbo].[vspSMTechnicianFormTechnicianVal] TO [public]
GO
