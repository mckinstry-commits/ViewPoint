SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Paul Wiegardt
-- Create date: 5/07/2013
-- Description:	SM trips for Dispatch
-- Modifications:
--				  5/10/13 GPT Task 49604 -- Added DispatchSequence to select clause.
--				  6/10/13 GPT Task 52182 -- Added VersionStamp to select clause.
--				  6/27/13 PW Task 53551 changed to all .* on vrvSMWorkOrderDispatch.
--				  7/02/13  GPT Task-53397 Return email column from employee record.
--				  10/10/13 DKS 	Task 64067 Defaulting start date to 6 months before end date if none provided
-- =============================================
CREATE PROCEDURE dbo.vspSMTripsGetByTechnicianAndDate
	@SMCo				bCompany,
	@TechnicianArray	varchar(max) = null,
	@StartDate			datetime = null, 
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

	-- Adding a default start date of six months prior to end date
	-- This dramatically increases the load time of the dispatch board
	-- For users with a large number of alerts / technicians.  Approved by Scott H on 10/10/2013
	if @StartDate IS NULL
	AND @EndDate IS NOT NULL
	BEGIN
		SET @StartDate = @EndDate - 180
	END
	
	SELECT 
		trip.Description,
		EstimatedDuration,
		trip.ScheduledDate,
		trip.SMTripID,
		trip.SMCo,
		trip.Status,
		trip.Technician,
		trip.Trip,
		trip.DispatchSequence,
		trip.VersionStamp,
		tech.FullName,
		tech.LastName,
		tech.FirstName,
		tech.MidName,
		tech.SMTechnicianID,
		employee.Email,
		work.*
	FROM @technicians technicians 
		inner join dbo.SMTechnicianInfo tech on tech.SMTechnicianID = technicians.techID
		inner join dbo.PREH employee ON employee.PRCo = tech.PRCo AND employee.Employee = tech.Employee
		left join dbo.SMTrip trip on trip.SMCo = tech.SMCo and trip.Technician = tech.Technician
		inner join dbo.vrvSMWorkOrderDispatch work on work.SMCo = trip.SMCo and work.WorkOrder = trip.WorkOrder
	WHERE 
			((trip.ScheduledDate is null) or (trip.ScheduledDate >= @StartDate or @StartDate is null))
		and ((trip.ScheduledDate is null) or (trip.ScheduledDate <= @EndDate or @EndDate is null))
		and trip.SMCo = @SMCo
	
	IF @@rowcount = 0
	BEGIN
		SET @msg = 'No Trips are available in that range'
		RETURN 1
	END
	
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMTripsGetByTechnicianAndDate] TO [public]
GO
