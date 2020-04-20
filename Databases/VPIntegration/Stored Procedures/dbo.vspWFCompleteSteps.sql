SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***********************************************************
* CREATED BY:  CC 07/08/2008
* MODIFIED By : 
*
* USAGE:
* 	This procedure checks for incomplete steps in a task
*
* INPUT PARAMETERS
*	@Company		Company
*	@Checklist		Checklist name
*	@Task			Task number
*   @Status			Status to update steps to
*
* RETURN
* 0 for success
* 1 for failure
*
* OUTPUT PARAMETERS
*   @msg      Error message
*
*****************************************************/
CREATE PROCEDURE [dbo].[vspWFCompleteSteps] 
	-- Add the parameters for the stored procedure here
	@Company int = null, 
	@Checklist VARCHAR(20) = null,
	@Task int = null,
	@Status int = null,
	@msg VARCHAR(512) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY
		UPDATE WFChecklistSteps SET WFChecklistSteps.Status = @Status
			FROM WFChecklistSteps
			INNER JOIN WFStatusCodes ON WFChecklistSteps.Status = WFStatusCodes.StatusID
			WHERE WFChecklistSteps.Company = @Company 
				  AND WFChecklistSteps.Checklist = @Checklist
				  AND WFChecklistSteps.Task = @Task
				  AND WFStatusCodes.StatusType <> 2

	END TRY

	BEGIN CATCH
		SET @msg = ERROR_MESSAGE()
		RETURN 1

	END CATCH

	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vspWFCompleteSteps] TO [public]
GO
