SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Paul Wiegardt
-- Create date: 5/07/2013
-- Description:	SM trips for Dispatch
-- Modifications: 
--                5/10/13 GPT Task 49604 Added DispatchSequence to select clause.
--				  6/10/13 GPT Task 52182 Added VersionStamp to select clause.
--				  6/27/13 PW Task 53551 changed to all .* on vrvSMWorkOrderDispatch.
-- =============================================
CREATE PROCEDURE dbo.vspSMTripsGetUnassignedByDate
	@SMCo				bCompany,
	@StartDate			datetime = null,
	@EndDate			datetime = null, 

	@msg				nvarchar OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
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
		null as FullName,
		null as SMTechnicianID,
		work.*
	FROM 
		dbo.SMTrip trip
		inner join dbo.vrvSMWorkOrderDispatch work on work.SMCo = trip.SMCo and work.WorkOrder = trip.WorkOrder
	WHERE 
			(trip.ScheduledDate >= @StartDate or @StartDate is null)
		and (trip.ScheduledDate <= @EndDate or @EndDate is null)
		and trip.SMCo = @SMCo
		and trip.Technician is null
	
	IF @@rowcount = 0
	BEGIN
		SET @msg = 'No Trips are available in that range'
		RETURN 1
	END
	
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMTripsGetUnassignedByDate] TO [public]
GO
