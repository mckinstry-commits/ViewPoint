SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Paul Wiegardt
-- Create date: 4/18/2013
-- Description:	SM Named Dispatch Boards
--
-- Modified by: GPT Task-53548 Return all technicians for @SMCo when board name is 'All'
--				GPT Task-53397 Return email column from employee record.
-- =============================================
CREATE PROCEDURE [dbo].[vspSMNamedDispatchBoardTechnician]
	@SMCo			bCompany,
	@SMBoardName	nvarchar(50),
	@msg nvarchar OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


	IF(@SMBoardName = 'All')
		BEGIN
			SELECT	tech.SMTechnicianID,
					tech.Technician,
					tech.FullName,
					tech.LastName,
					tech.FirstName,
					tech.MidName,
					employee.Email
			FROM dbo.SMTechnicianInfo tech
			INNER JOIN dbo.PREH employee ON employee.PRCo = tech.PRCo AND employee.Employee = tech.Employee
			WHERE SMCo = @SMCo 
		END
	ELSE
		BEGIN
			SELECT	tech.SMTechnicianID,
					tech.Technician,
					tech.FullName,
					tech.LastName,
					tech.FirstName,
					tech.MidName,
					employee.Email
			FROM dbo.SMNamedDispatchBoardTechnician
				inner join dbo.SMTechnicianInfo tech on tech.Technician = SMNamedDispatchBoardTechnician.Technician 
					and tech.SMCo = SMNamedDispatchBoardTechnician.SMCo
				inner join dbo.PREH employee ON employee.PRCo = tech.PRCo AND employee.Employee = tech.Employee
			WHERE SMNamedDispatchBoardTechnician.SMCo = @SMCo and SMBoardName = @SMBoardName
		END

	IF @@rowcount = 0
	BEGIN
		SET @msg = 'No Technicians are available.'
		RETURN 1
	END
	
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMNamedDispatchBoardTechnician] TO [public]
GO
