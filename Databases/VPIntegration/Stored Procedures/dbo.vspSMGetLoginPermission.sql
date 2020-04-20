SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Vaterlaus
-- Create date: 03/03/2011
-- Description:	Get permission for user login to edit timesheet data for specific employee.
-- =============================================
CREATE PROCEDURE [dbo].[vspSMGetLoginPermission]
	@PRCo bCompany,
	@Employee bEmployee,
	@loginname as varchar(40)=NULL,
	@TimesheetEditOkay bYN=NULL OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
/* Flag to print debug statements */

DECLARE @PrintDebug bit
Set @PrintDebug=0

	DECLARE @TimesheetRevGroup varchar(10), @entryemplprgroup bGroup, @rcode int,
		@msg varchar(255), @MyTimesheetRole tinyint, @loginemployee bEmployee

	IF (@loginname IS NULL)
	BEGIN
		SELECT @loginname = suser_name()
	END
	
	SELECT @entryemplprgroup=bPREH.PRGroup, @MyTimesheetRole=MyTimesheetRole,
	@loginemployee=DDUP.Employee	
	FROM DDUP
	INNER JOIN bPREH ON DDUP.Employee=bPREH.Employee
	WHERE DDUP.VPUserName = @loginname AND bPREH.PRCo=DDUP.PRCo
	
IF (@PrintDebug=1) PRINT 'vspSMGetLoginPermission 1: loginname='+@loginname

	IF (@MyTimesheetRole>1 OR @loginemployee=@Employee)
	BEGIN
		exec @rcode = vspPRMyTimesheetEmpVal @prco=@PRCo, @empl=@Employee, @entryemplprgroup=@entryemplprgroup, @msg=@msg OUTPUT
	END
	ELSE
	BEGIN
		SET @rcode=1
	END

	IF (@rcode=0)
		SET @TimesheetEditOkay='Y'
	ELSE
		SET @TimesheetEditOkay='N'
	
END

GO
GRANT EXECUTE ON  [dbo].[vspSMGetLoginPermission] TO [public]
GO
