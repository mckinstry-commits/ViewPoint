SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Vaterlaus
-- Create date: 01/20/2011
-- Description:	Lookup a SM technician given an Employee number and PRCo
-- =============================================
CREATE PROCEDURE [dbo].[vspSMTechnicianLookupFromEmployee]
	-- Add the parameters for the stored procedure here
	@SMCo bCompany, @PRCo as bCompany, @Employee int, @Technician varchar(15)=NULL OUTPUT, @msg varchar(100) = NULL OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	SELECT @Technician=Technician FROM SMTechnician WHERE SMCo = @SMCo AND PRCo = @PRCo
	AND Employee = @Employee
	IF @@ROWCOUNT = 0
		BEGIN
			SET @msg = 'Employee ' + CONVERT(varchar, @Employee) + ' is not valid for SM company ' + @SMCo + '.'
			RETURN 1
		END
	
	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vspSMTechnicianLookupFromEmployee] TO [public]
GO
