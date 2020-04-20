SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 1/20/11
-- Modified:    ECV 04/19/11 TK-04236 Added default SMCo from PRCo
-- Description:	Load proc for PR My Timesheet forms
-- =============================================
CREATE PROCEDURE [dbo].[vspPRMyTimesheetLoadProc]
	@PRCo bCompany, @EmployeePRCo bCompany OUTPUT, @Employee bEmployee OUTPUT, @TimesheetRole tinyint OUTPUT,
	@EmployeeName varchar(83) OUTPUT, @PRGroup bGroup OUTPUT, @AllowNoPhase bYN OUTPUT, @SMCoDefault bCompany OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @VPUserName VARCHAR(255)

    SET @VPUserName = SUSER_NAME()
    
    SELECT @EmployeePRCo = PRCo, @Employee = Employee, @TimesheetRole = MyTimesheetRole
    FROM dbo.DDUP
    WHERE VPUserName = @VPUserName
    
    SELECT @EmployeeName = FullName, @PRGroup = PRGroup
    FROM dbo.PREHFullName
	WHERE PRCo = @EmployeePRCo AND Employee = @Employee
	
	SELECT @AllowNoPhase = AllowNoPhase, @SMCoDefault=SMCo
	FROM dbo.PRCO
	WHERE PRCo = @PRCo
END

GO
GRANT EXECUTE ON  [dbo].[vspPRMyTimesheetLoadProc] TO [public]
GO
