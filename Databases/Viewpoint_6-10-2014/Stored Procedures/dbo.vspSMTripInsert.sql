SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Aaron Lang
-- Create date:	4/10/13
-- Description:	SM trip insert
--				
-- Modified		6/10/13 GPT Task 52182 Added VersionStamp  as output.
-- =============================================
CREATE PROCEDURE dbo.vspSMTripInsert
	@WorkOrderID int,
	@TechnicianID int = null, 
	@Date datetime = NULL, 
	@TripID int OUTPUT, 
	@Trip	int OUTPUT, 
	@VersionStamp binary(8) OUTPUT,
	@msg varchar(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @technician varchar(15), @SMCo bCompany, @WorkOrder nvarchar(20)
	
	Declare @SMTripIDTable table(SMTripID int NOT NULL, VersionStamp binary(8) NOT NULL)

	IF @WorkOrderID IS NULL
	BEGIN
		SET @msg = 'Missing SM Work Order!'
		RETURN 1
	END

	SELECT @technician = Technician from SMTechnician Where SMTechnicianID = @TechnicianID

	SELECT @SMCo = SMCo, @WorkOrder = WorkOrder from SMWorkOrder Where SMWorkOrderID = @WorkOrderID 

	SELECT @Trip = isnull(MAX(Trip)+1, 1) from SMTrip where WorkOrder = @WorkOrder and SMCo = @SMCo

	INSERT INTO dbo.SMTrip
			(SMCo
			,WorkOrder
			,Trip
			,Status
			,ScheduledDate
			,Technician)
	 OUTPUT Inserted.SMTripID, Inserted.VersionStamp INTO @SMTripIDTable
     VALUES
			(@SMCo,
			@WorkOrder,
			@Trip,
			0, -- status == New
			@Date,
			@technician)

	SELECT @TripID = SMTripID, @VersionStamp = VersionStamp FROM @SMTripIDTable

END
GO
GRANT EXECUTE ON  [dbo].[vspSMTripInsert] TO [public]
GO
