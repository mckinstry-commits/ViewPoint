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
*   
*
* RETURN
* 0 for success
* 1 for failure
*
* OUTPUT PARAMETERS
*   @msg      Error message
*
*****************************************************/
CREATE PROCEDURE [dbo].[vspWFCheckIncompleteSteps] 
	-- Add the parameters for the stored procedure here
	@Company int = null, 
	@Checklist VARCHAR(20) = null,
	@Task int = null,
	@Status int = null,
	@msg VARCHAR(512) OUTPUT
AS
BEGIN
	SET NOCOUNT ON;

	SET @msg = ''

	IF EXISTS (SELECT TOP 1 1
				FROM WFStatusCodes 
				WHERE WFStatusCodes.StatusID = @Status
					  AND WFStatusCodes.StatusType <> 2) 
		RETURN 0;		
    
	DECLARE @StepCount int	
	SET @StepCount = 0

	SELECT @StepCount = COUNT(*) 
			FROM WFChecklistSteps 
			INNER JOIN WFStatusCodes ON WFChecklistSteps.Status = WFStatusCodes.StatusID
			WHERE WFChecklistSteps.Company = @Company 
				  AND WFChecklistSteps.Checklist = @Checklist
				  AND WFChecklistSteps.Task = @Task
				  AND WFStatusCodes.StatusType <> 2
	
	IF @StepCount <> 0
		BEGIN
			SELECT @msg = 
					CASE @StepCount 
						WHEN 1 THEN 'There is one uncompleted step. Do you want to complete it with the current status?'
						ELSE 'There are ' + CAST(@StepCount AS VARCHAR(10)) + ' uncompleted steps. Do you want to complete them with the current status?'
					END
			RETURN 0
		END

	SET @msg = ''
	RETURN 0
END

GO
GRANT EXECUTE ON  [dbo].[vspWFCheckIncompleteSteps] TO [public]
GO
