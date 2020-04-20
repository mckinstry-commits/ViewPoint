SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Lane Gresham
-- Create date: 02/03/11
-- Description:	Validation for SM technician and also checks
--			    if that technician is being used that day. 
-- =============================================
CREATE PROCEDURE [dbo].[vspSMTechnicianDateVal]
	@SMCo bCompany, 
	@WorkOrder int, 
	@Trip int,
	@Technician varchar(15), 
	@ScheduledDate bDate,
	@TechnicianOverBooked VARCHAR(MAX) = NULL OUTPUT,
	@msg varchar(255) = NULL OUTPUT
AS
BEGIN

	SET NOCOUNT ON;
	
	DECLARE @rcode int 
	DECLARE @date datetime
	
	SET @date = datepart(dw, @ScheduledDate)
	
	EXEC @rcode = dbo.vspSMTechnicianVal @SMCo = @SMCo, @Technician = @Technician, @msg = @msg OUTPUT
    IF @rcode <> 0 
    BEGIN
		RETURN @rcode
    END
    ELSE
    BEGIN
		
		SET @TechnicianOverBooked = 'Warning: ' + dbo.vfLineBreak() + 'Technician is currently scheduled for: '
		
		SELECT @TechnicianOverBooked = dbo.vfSMBuildString(@TechnicianOverBooked, 'Work Order: ' + dbo.vfToString(WorkOrder) + ' Trip: ' + dbo.vfToString(Trip) + ' Estimated Duration: ' + CASE WHEN EstimatedDuration IS NULL THEN 'N/A' ELSE dbo.vfToString(EstimatedDuration) END, dbo.vfLineBreak())
		FROM dbo.SMTrip
		WHERE SMCo = @SMCo AND 
			Technician = @Technician AND 
			ScheduledDate = @ScheduledDate 
			AND NOT (WorkOrder = @WorkOrder AND Trip = @Trip)
			
		IF @@rowcount = 0
		BEGIN
			SET @TechnicianOverBooked = NULL
		END
		
		IF EXISTS
		(
			SELECT 1 FROM dbo.SMTechnician
			WHERE SMCo = @SMCo AND Technician = @Technician AND
			NOT (CASE @date
				WHEN 1 THEN SMTechnician.Sunday
				WHEN 2 THEN SMTechnician.Monday
				WHEN 3 THEN SMTechnician.Tuesday 
				WHEN 4 THEN SMTechnician.Wednesday
				WHEN 5 THEN SMTechnician.Thursday
				WHEN 6 THEN SMTechnician.Friday
				WHEN 7 THEN SMTechnician.Saturday
			END) = 'Y'
		)
		BEGIN
			SET @TechnicianOverBooked = ISNULL(@TechnicianOverBooked, 'Warning:' ) + dbo.vfLineBreak() + 'You are scheduling this technician outside his/her normal work hours.'
		END
		
    END

	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vspSMTechnicianDateVal] TO [public]
GO
