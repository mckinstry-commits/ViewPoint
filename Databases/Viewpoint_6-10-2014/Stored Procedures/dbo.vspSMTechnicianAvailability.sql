SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Paul Wiegardt
-- Create date: 4/2/2013
-- Description:	SM Technician Availability
-- Modified:	5/15/2013 TFS 49602 GPT - Query scheduled booleans if tech is set to work on a given day.
-- =============================================
CREATE PROCEDURE dbo.vspSMTechnicianAvailability
	@TechnicianArray varchar(max),
	@msg nvarchar OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	IF @TechnicianArray IS NULL
	BEGIN
		SET @msg = 'Missing @TechnicianArray'
		RETURN 1
	END
	
	declare @technicians table(techID int)
	insert @technicians
	select Names from vfTableFromArray(@TechnicianArray)
	
	select
		SMTechnicianID
	,	datediff(hour,MondayWorkStart,MondayWorkEnd) - coalesce(datediff(hour,MondayBreakStart,MondayBreakEnd), 0) as MondayHours
	,	datediff(hour,TuesdayWorkStart,TuesdayWorkEnd) - coalesce(datediff(hour,TuesdayBreakStart,TuesdayBreakEnd), 0) as TuesdayHours
	,	datediff(hour,WednesdayWorkStart,WednesdayWorkEnd) - coalesce(datediff(hour,WednesdayBreakStart,WednesdayBreakEnd), 0) as WednesdayHours
	,	datediff(hour,ThursdayWorkStart,ThursdayWorkEnd) - coalesce(datediff(hour,ThursdayBreakStart,ThursdayBreakEnd), 0) as ThursdayHours
	,	datediff(hour,FridayWorkStart,FridayWorkEnd) - coalesce(datediff(hour,FridayBreakStart,FridayBreakEnd), 0) as FridayHours
	,	datediff(hour,SaturdayWorkStart,SaturdayWorkEnd) - coalesce(datediff(hour,SaturdayBreakStart,SaturdayBreakEnd), 0) as SaturdayHours
	,	datediff(hour,SundayWorkStart,SundayWorkEnd) - coalesce(datediff(hour,SundayBreakStart,SundayBreakEnd), 0) as SundayHours
	-- Return scheduled days
	,	Sunday as scheduledSunday
	,	Monday as scheduledMonday
	,	Tuesday as scheduledTuesday
	,	Wednesday as scheduledWednesday 
	,	Thursday as scheduledThursday
	,	Friday as scheduledFriday 
	,	Saturday as scheduledSaturday 
	from SMTechnician
		inner join @technicians on SMTechnicianID = techID
	
	IF @@rowcount = 0
	BEGIN
		SET @msg = 'No Trips are available in that range'
		RETURN 1
	END
	
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMTechnicianAvailability] TO [public]
GO
