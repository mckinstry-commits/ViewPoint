SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		TomJ
-- Create date: 2011/10/25
-- Description:	Updates the DDUPRecord with the proper settings
-- =============================================
CREATE PROCEDURE [dbo].[vpspUpdateDDUPRecord] 
	@VPUserName varchar(40),
	@HRCo bCompany,
	@HRRef bHRRef,
	@PRCo bCompany,
	@PREmployee bEmployee,
	@TimeSheetRole tinyint
AS
BEGIN
	UPDATE DDUP SET HRCo = @HRCo, HRRef = @HRRef, PRCo = @PRCo, Employee = @PREmployee, 
			MyTimesheetRole = @TimeSheetRole WHERE VPUserName = @VPUserName
END

GO
GRANT EXECUTE ON  [dbo].[vpspUpdateDDUPRecord] TO [VCSPortal]
GO
