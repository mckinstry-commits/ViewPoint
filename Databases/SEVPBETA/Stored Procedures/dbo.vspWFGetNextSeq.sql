SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***********************************************************
* CREATED BY:  Charles Courchaine 1/21/2008
* MODIFIED By : CC 6/26/2009 #130980 - increase item length to 60 for templates
*
* USAGE:
* 	Gets the next number for a task or step
*
* INPUT PARAMETERS
*	@Company		Company #
*	@Item			A particluar checklist or template to look for
*	@Task			Optional to get next seq. for a task/step
*   
* OUTPUT PARAMETERS
*   @NextNumber      Next sequence number
*
*****************************************************/

CREATE PROCEDURE [dbo].[vspWFGetNextSeq] 
	-- Add the parameters for the stored procedure here
	@Company bCompany = null,
	@Item varchar(60) = null,
	@Task int = null, 
	@NextNumber int = null OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
IF @Company is null --Template
	If @Task = 0 --get next for task
		select @NextNumber = isnull((max(Task)+1),1) from WFTemplateTasks where Template = @Item
	else --get next for step
		select @NextNumber = isnull((max(Step)+1),1) from WFTemplateSteps where Template = @Item and Task = @Task
ELSE --Checklist
	If @Task = 0 --get next for task
		select @NextNumber = isnull((max(Task)+1),1) from WFChecklistTasks where Checklist = @Item and Company = @Company
	else --get next for step
		select @NextNumber = isnull((max(Step)+1),1) from WFChecklistSteps where Checklist = @Item and Company = @Company and Task = @Task
END


GO
GRANT EXECUTE ON  [dbo].[vspWFGetNextSeq] TO [public]
GO
