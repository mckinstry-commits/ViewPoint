SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************************
* Author:		CC
* Create date:  1/24/2008
* Description:	Sends notification to all users who can start their work on a given checklist
* Modified:		CC 7/28/2008 - Issue 129179: Change optional activity text.
*				CC 8/26/2008 - Issue 129564: Update email information
*
*	Inputs:
*	@Company		Company checklist is located in
*	@Checklist		Checklist to send notifications on
*
*****************************************************/
CREATE PROCEDURE [dbo].[vspWFNotifyAll] 
	-- Add the parameters for the stored procedure here
	@Company bCompany = null, 
	@Checklist VARCHAR(20) = null,
    @emailFrom VARCHAR(55) = null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	
	SELECT @emailFrom = COALESCE(@emailFrom, 'viewpointcs') 

	DECLARE @IsChecklistMixed bYN
	
	IF EXISTS (SELECT TOP 1 1 
				FROM WFChecklistTasks 
				INNER JOIN WFChecklists ON WFChecklistTasks.Checklist = WFChecklists.Checklist AND WFChecklistTasks.Company = WFChecklists.Company
				WHERE WFChecklistTasks.Checklist = @Checklist AND WFChecklistTasks.Company = @Company AND WFChecklistTasks.IsTaskRequired = 'Y' AND WFChecklists.EnforceOrder = 'Y')
		SET @IsChecklistMixed = 'Y'
	ELSE
		SET @IsChecklistMixed = 'N'


	INSERT INTO vMailQueue ([To], CC, BCC, [From], [Subject], Body, Source)
			SELECT DDUP.EMail, '', '', @emailFrom AS [From],
					CASE WFTasklist.[Type]
						WHEN 'Task' THEN 'New Checklist Task: '
						WHEN 'Step' THEN 'New Checklist Step: ' 
					END							
					+ WFTasklist.Summary + ' on Checklist: ' + @Checklist + ' has been assigned to you' as [Subject]
					,CASE WFTasklist.[Type]
						WHEN 'Task' THEN 'You have been assigned to task ' + CAST(WFTasklist.Task AS VARCHAR(5)) + WFTasklist.Summary + ' on Checklist: ' + WFTasklist.Checklist + '.'
						WHEN 'Step' THEN 'You have been assigned to task ' + CAST(WFTasklist.Task AS VARCHAR(5)) + ', step ' +  CAST(WFTasklist.Step AS VARCHAR(5)) + ' ' + WFTasklist.Summary + ' on Checklist: ' + WFTasklist.Checklist + '.'
					END
					+ CHAR(13) + CHAR(10) +
					CASE
						WHEN WFTasklist.Required = 'Y' OR (WFTasklist.Required = 'N' AND @IsChecklistMixed = 'N') THEN 'This is a required ' + LOWER(WFTasklist.[Type]) + ' on this checklist.  Failure to complete this activity will prevent this checklist from being completed.'
						ELSE 'This is not a required ' + LOWER(WFTasklist.[Type])  + ' on this checklist.  This is the only notice you will receive regarding this activity.'
					END 
					AS [Body] 
					,'Workflow'
		FROM WFTasklist
		INNER JOIN DDUP ON WFTasklist.AssignedTo = DDUP.VPUserName
		INNER JOIN WFStatusCodes ON	WFTasklist.Status = WFStatusCodes.StatusID
	WHERE WFTasklist.Company = @Company 
			AND WFTasklist.Checklist = @Checklist 
			AND DDUP.EMail IS NOT NULL
			AND WFStatusCodes.StatusType = 0
END	
GO
GRANT EXECUTE ON  [dbo].[vspWFNotifyAll] TO [public]
GO
