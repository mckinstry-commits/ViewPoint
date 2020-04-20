SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Paul Wiegardt
-- Create date: 5/1/2013
-- Description:	SM trips for Dispatch
-- Modifications: 
--                5/10/13 GPT Task 49604 Added DispatchSequence to select clause.
--				  6/10/13 GPT Task 52182 Added VersionStamp to select clause.
--				  7/02/13 GPT Task-53397 Return email column from employee record.
-- =============================================
CREATE PROCEDURE dbo.vspSMTripsGet
	@SMTripID	int,
	@Debug int = 0,
	@msg nvarchar OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	SELECT
		trip.Description,
		trip.Details,
		coalesce(trip.EstimatedDuration,0) as EstimatedDuration,
		trip.ScheduledDate,
		trip.SMTripID,
		trip.SMCo,
		trip.Status,
		trip.Technician,
		trip.Trip,
		trip.DispatchSequence,
		trip.VersionStamp,
		tech.FullName,
		tech.SMTechnicianID,
		work.WorkOrder,
		work.Customer,
		work.ServiceSite,
		work.SMWorkOrderID,
		work.Description as WorkOrderDescription
	FROM dbo.SMTrip trip
		left join dbo.SMTechnicianInfo tech on trip.SMCo = tech.SMCo and trip.Technician = tech.Technician
		left join dbo.PREH employee ON employee.PRCo = tech.PRCo AND employee.Employee = tech.Employee
		left join dbo.SMWorkOrder work on work.SMCo = trip.SMCo and work.WorkOrder = trip.WorkOrder
	WHERE trip.SMTripID = @SMTripID

	IF @@rowcount = 0
	BEGIN
		SET @msg = 'No Trips are available in that range'
		RETURN 1
	END
	
	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMTripsGet] TO [public]
GO
