SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Eric Vaterlaus
-- Create date: 3/07/2011
-- Modified: LaneG 8/23/11 - Added vspSMTechnicianVal
-- Description:	Validation of SM technician for Work Completed Labor record.
-- =============================================
CREATE PROCEDURE [dbo].[vspSMTechnicianWorkCompletedVal]
	@SMCo bCompany, 
	@Technician varchar(15), 
	@LineType tinyint = NULL, 
	@PREndDate bDate = NULL,
	@WorkOrder int,
	@PRCo bCompany = NULL OUTPUT, 
	@Employee bEmployee = NULL OUTPUT, 
	@Shift tinyint = 1 OUTPUT, 
	@EarnCode varchar(5) = NULL OUTPUT, 
	@Craft varchar(10) = NULL OUTPUT, 
	@Class varchar(10) = NULL OUTPUT, 
	@INCo bCompany = NULL OUTPUT,
	@INLocation	bLoc = NULL OUTPUT,
	@msg varchar(255)=NULL OUTPUT
AS
BEGIN
	SET NOCOUNT ON;
	/* Flag to print debug statements */
	DECLARE @PrintDebug bit
	Set @PrintDebug=0

	DECLARE @TimesheetEditOkay bYN, @rcode int,@entryemplprgroup bGroup, @MyTimesheetRole tinyint,
	@EntryEmployee bEmployee, @entryPRCo bCompany, @SMPRCo bCompany, @JCCo bCompany, @Job bJob, @JobCraft bCraft
	
	EXEC @rcode = vspSMTechnicianVal @SMCo, @Technician, @PRCo OUTPUT, NULL, @INCo OUTPUT, @INLocation OUTPUT, @msg OUTPUT
	
	IF @rcode <> 0
	BEGIN
		RETURN 1
	END

	IF (@LineType=2)
	BEGIN
		IF (NOT @PREndDate IS NULL)
		BEGIN
			/* Timecard record has been posted. */
			SET @msg = 'Timecard record has been posted.'
			RETURN 1
		END
		SELECT @Employee = Employee FROM SMTechnician WHERE SMCo=@SMCo AND Technician=@Technician
		
		exec @rcode = vspPRMyTimesheetEmpVal @prco=@PRCo, @empl=@Employee, @entryemplprgroup=@entryemplprgroup, 
		@craft=@Craft output, @class=@Class output, @shift=@Shift output, @earncode=@EarnCode output,
		@msg=@msg OUTPUT

		SET @Shift=ISNULL(@Shift,1)

		SELECT @JCCo=JCCo, @Job=Job FROM SMWorkOrder WHERE SMCo = @SMCo AND WorkOrder = @WorkOrder
		IF (@Job IS NOT NULL)
		BEGIN
			-- Since this is a Job Work Order, call the Job validation to get a default Craft value
			EXEC @rcode = vspPRMyTimesheetJobVal @PRCo, @Employee, @JCCo, @Job, @JobCraft OUTPUT, NULL, @msg OUTPUT
			IF @rcode=0 AND @JobCraft IS NOT NULL
			BEGIN
				SET @Craft = @JobCraft
			END
		END
		IF (NOT @rcode=0)
		BEGIN
			RETURN 1
		END			
	END

	RETURN 0
END
GO
GRANT EXECUTE ON  [dbo].[vspSMTechnicianWorkCompletedVal] TO [public]
GO
