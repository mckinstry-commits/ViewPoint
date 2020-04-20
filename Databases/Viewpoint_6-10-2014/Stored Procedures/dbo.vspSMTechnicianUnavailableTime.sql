SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Paul Wiegardt
-- Create date: 5/07/2013
-- Description:	Select SM Technician Unavailable Time
-- Modifications:
-- =============================================
CREATE PROCEDURE dbo.vspSMTechnicianUnavailableTime
	@SMCo				bCompany,
	@TechnicianArray	varchar(max),
	@StartDate			datetime,
	@EndDate			datetime = null, 

	@Debug				int = 0,
	@msg				nvarchar OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	declare @technicians table(techID int)
	
	insert @technicians
	select Names from vfTableFromArray(@TechnicianArray)

	if @Debug = 1 select * FROM @technicians technicians 
		inner join dbo.SMTechnicianInfo tech on tech.SMTechnicianID = technicians.techID
	
	SELECT 
		ut.*,
		tech.FullName,
		tech.SMTechnicianID
	FROM @technicians technicians 
		inner join dbo.SMTechnicianInfo tech on tech.SMTechnicianID = technicians.techID
		inner join dbo.SMTechnicianUnavailableTime ut on ut.SMCo = tech.SMCo and ut.Technician = tech.Technician
	WHERE 
			(ut.StartDate >= @StartDate)
		and ((ut.EndDate is null) or (ut.EndDate <= @EndDate or @EndDate is null))
		and ut.SMCo = @SMCo
	
	IF @@rowcount = 0
	BEGIN
		SET @msg = 'No Trips are available in that range'
		RETURN 1
	END
	
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMTechnicianUnavailableTime] TO [public]
GO
