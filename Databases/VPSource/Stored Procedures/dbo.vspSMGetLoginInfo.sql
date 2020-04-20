SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Eric Vaterlaus
-- Create date: 03/03/2011
-- Description:	Get information employee about the current logged in user.
-- =============================================
CREATE PROCEDURE [dbo].[vspSMGetLoginInfo]
	@SMCo int,
	@loginname as varchar(40)=NULL,
	@Technician varchar(15)=NULL OUTPUT,
	@PRCo bCompany=NULL OUTPUT,
	@Employee bEmployee=NULL OUTPUT,
	@EnterTimesheetsForThemselves bYN=NULL OUTPUT,
	@EnterTimesheetsForOthers bYN=NULL OUTPUT
AS
BEGIN
	/*
		DDUP.PRCo
		DDUP.Employee
		DDUP.MyTimesheetRole
			0 = Cannot enter/change timesheets.
			1 = Can enter/change timesheets for themselves.
			2 = Can enter/change timesheets for themselves and others.
			3 = Can enter/change timesheets for themselves and others.
	*/
	SET NOCOUNT ON;

	IF (@loginname IS NULL)
	BEGIN
		SELECT @loginname = suser_name()
	END
	
	SELECT @PRCo=vDDUP.PRCo, @Employee=vDDUP.Employee,
		@EnterTimesheetsForThemselves =
			CASE WHEN ISNULL(vDDUP.MyTimesheetRole,0) >= 1 THEN 'Y'
				ELSE 'N'
			END,
		@EnterTimesheetsForOthers =
			CASE WHEN ISNULL(vDDUP.MyTimesheetRole,0) >= 2 THEN 'Y'
				ELSE 'N'
			END,
		@Technician = vSMTechnician.Technician
	FROM vDDUP
	LEFT JOIN vSMTechnician ON vSMTechnician.SMCo=@SMCo
		AND vDDUP.PRCo = vSMTechnician.PRCo
		AND vDDUP.Employee = vSMTechnician.Employee
	WHERE vDDUP.VPUserName = @loginname
	
	IF (@PRCo IS NULL OR @Employee IS NULL)
	BEGIN
		SELECT @EnterTimesheetsForThemselves='N',@EnterTimesheetsForOthers='N'
	END

END

GO
GRANT EXECUTE ON  [dbo].[vspSMGetLoginInfo] TO [public]
GO
