SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Aaron Lang
-- Create date: 4/10/13
-- Description:	SM trip update
-- Modifications: 
--				  5/10/13 GPT Task 49604 Added DispatchSequence to update clause.
--				  6/10/13 GPT Task 47479 Added VersionStamp as an output param.
-- =============================================
CREATE PROCEDURE [dbo].[vspSMTripUpdate]
	@TripID			 int, 
	@TechnicianID	 int = null, 
	@Date			 datetime = NULL,
	@DispatchSequence int = NULL,
	@Status			 tinyint = NULL,
	@VersionStamp	binary(8) OUTPUT,
	@msg			varchar(255) OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @technician varchar(15)
	SELECT @technician = Technician from SMTechnician Where SMTechnicianID = @TechnicianID

	update [dbo].[SMTrip]
		set Technician = @technician, ScheduledDate = @Date,
		 DispatchSequence = @DispatchSequence, Status = ISNULL(@Status, Status)
		where SMTripID = @TripID

	-- Return the new version stamp for the updated trip
	SELECT @VersionStamp = VersionStamp FROM SMTrip WHERE SMTripID = @TripID
END
GO
GRANT EXECUTE ON  [dbo].[vspSMTripUpdate] TO [public]
GO
