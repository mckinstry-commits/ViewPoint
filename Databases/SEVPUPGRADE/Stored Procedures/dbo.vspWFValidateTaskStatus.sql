SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************************
* Author:		Charles Courchaine
* Create date:  1/30/2008
* Description:	Enforces 'enforce order' option, and task/step status consistency
*
*	Inputs:
*	
*	@Checklist  Checklist task resides in
*	@Task		Task to validate status for
*	@Company	Company checklist resides in
*	@Status		Status the task is being updated to
*
*	Outputs:
*	@msg			Validation message
*
*****************************************************/
CREATE PROCEDURE [dbo].[vspWFValidateTaskStatus] 
	-- Add the parameters for the stored procedure here
	@Checklist varchar(20) = null, 
	@Task int = null,
	@Company bCompany = null,
	@Status int = null,
	@msg varchar(512) = null OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	EXEC dbo.[vspWFStatusValWithInfo] @Status = @Status, @msg = @msg OUTPUT
	IF @msg = 'Invalid status '
		RETURN
	ELSE
		SET @msg = NULL

	if (select EnforceOrder 
			from WFChecklists 
			where Checklist = @Checklist and Company = @Company) = 'Y'
		if exists (select top 1 1 
						from WFChecklistTasks t
							where t.Checklist = @Checklist and t.Company = @Company and t.IsTaskRequired = 'Y')
		BEGIN
			if exists (select top 1 1
						from WFChecklistTasks t
							where t.Checklist = @Checklist and t.Company = @Company and t.Task = @Task and t.IsTaskRequired = 'Y')
				if exists (select top 1 1 
							from WFChecklistTasks t
							where t.Checklist = @Checklist and t.Company = @Company and t.Task < @Task and t.IsTaskRequired = 'Y'
								  and [Status] in (select StatusID from WFStatusCodes where StatusType <> 2 and IsChecklistStatus ='N'))
					and
					not exists (select top 1 1 from WFStatusCodes where StatusType = 0 and StatusID = @Status)
					BEGIN
						select @msg = 'There are uncompleted required tasks before this task, please complete those first'
						return
					END
		END
		else
		BEGIN
			if exists (select top 1 1 
							from WFChecklistTasks t
							where t.Checklist = @Checklist and t.Company = @Company and t.Task < ANY (select @Task) 
								  and [Status] in (select StatusID from WFStatusCodes where StatusType <> 2 and IsChecklistStatus ='N'))
				and
				not exists (select top 1 1 from WFStatusCodes where StatusType = 0 and StatusID = @Status)
					BEGIN
						select @msg = 'There are uncompleted tasks before this task, please complete those first'
						return
					END
		END
	if exists(select top 1 1 from WFChecklistSteps 
				where Company = @Company and Checklist = @Checklist and Task = @Task 
					and [Status] in (select StatusID from WFStatusCodes where StatusType in (1,2) and IsChecklistStatus ='N'))
	   and exists (select top 1 1 from WFStatusCodes where StatusID = @Status and StatusType = 0)
		BEGIN
			select @msg = 'There are in progress/final steps associated with this task, it cannot be set to a new status'
			return
		END
END

GO
GRANT EXECUTE ON  [dbo].[vspWFValidateTaskStatus] TO [public]
GO
