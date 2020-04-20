SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Aaron Lang
-- Create date: 6/23/2013
-- Description:	Get open trips for a specific Work Order
-- =============================================
CREATE PROCEDURE [dbo].[vspSMGetTripsForWorkOrder]
	@SMCo	bCompany,
	@WorkOrder int,
	@msg nvarchar OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	SELECT
		trip.[Description],
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
		tech.LastName,
		tech.FirstName,
		tech.MidName,
		tech.SMTechnicianID,
		work.WorkOrder,
		work.Customer,
		work.ServiceSite,
		work.SMWorkOrderID,
		work.[Description] as WorkOrderDescription
	FROM dbo.SMTrip trip
		left join dbo.SMTechnicianInfo tech on trip.SMCo = tech.SMCo and trip.Technician = tech.Technician
		left join dbo.SMWorkOrder work on work.SMCo = trip.SMCo and work.WorkOrder = trip.WorkOrder
	WHERE trip.WorkOrder = @WorkOrder AND trip.SMCo = @SMCo AND trip.Status = 0
	
	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vspSMGetTripsForWorkOrder] TO [public]
GO
