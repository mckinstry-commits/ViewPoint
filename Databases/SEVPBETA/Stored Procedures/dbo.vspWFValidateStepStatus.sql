SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************************
* Author:		Charles Courchaine
* Create date:  1/30/2008
* Description:	Enforces 'enforce order' option, and task/step status consistancy
*
*	Inputs:
*	
*	@Checklist  Checklist task resides in
*	@Task		Task step resides in
*	@Step		Step to validate status for
*	@Company	Company checklist resides in
*	@Status		Status the task is being updated to
*
*	Outputs:
*	@msg			Validation message
*
*****************************************************/
CREATE PROCEDURE [dbo].[vspWFValidateStepStatus] 
	-- Add the parameters for the stored procedure here
	@Checklist varchar(20) = null, 
	@Task int = null,
	@Step int = null,
	@Company bCompany = null,
	@Status int = null,
	@msg varchar(512) = null OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

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
							where t.Checklist = @Checklist and t.Company = @Company and t.Task < ANY (select @Task) and t.IsTaskRequired = 'Y'
								  and [Status] in (select StatusID from WFStatusCodes where StatusType <> 2 and IsChecklistStatus ='N'))
					and
					not exists (select top 1 1 from WFStatusCodes where StatusType = 0 and StatusID = @Status)
					BEGIN
						select @msg = 'There are uncompleted required tasks before this task, please complete those first'
						return
					END
				if exists (select top 1 1
							from WFChecklistSteps s
							where s.Checklist = @Checklist and s.Company = @Company and s.Task = @Task 
								  and s.Step < ANY (select @Step) and s.IsStepRequired = 'Y'
								  and [Status] in (select StatusID from WFStatusCodes where StatusType <> 2 and IsChecklistStatus ='N'))
					and exists (select top 1 1 from WFChecklistSteps s where s.Checklist = @Checklist and s.Company = @Company and s.Task = @Task and s.Step = @Step and s.IsStepRequired = 'Y')
					and
					not exists (select top 1 1 from WFStatusCodes where StatusType = 0 and StatusID = @Status)
					BEGIN
						select @msg = 'There are uncompleted required steps before this step, please complete those first'
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
						select @msg = 'There are uncompleted required tasks before this task, please complete those first'
						return
					END
				if exists (select top 1 1
							from WFChecklistSteps s
							where s.Checklist = @Checklist and s.Company = @Company and s.Task = @Task 
								  and s.Step < ANY (select @Step) 
								  and [Status] in (select StatusID from WFStatusCodes where StatusType <> 2 and IsChecklistStatus ='N'))
					and
					not exists (select top 1 1 from WFStatusCodes where StatusType = 0 and StatusID = @Status)
					BEGIN
						select @msg = 'There are uncompleted required steps before this step, please complete those first'
						return
					END
		END
	if exists(select top 1 1 
				from WFChecklistTasks t
				where t.Checklist = @Checklist and t.Company = @Company and t.Task = @Task 
					  and [Status] in (select StatusID from WFStatusCodes where StatusType = 2))
		and exists (select top 1 1
				from WFStatusCodes
				where StatusType <> 2 and StatusID = @Status)
		BEGIN
			select @msg = 'Task is in a final state, steps cannot be set to a non-final state'
			return
		END
END

GO
GRANT EXECUTE ON  [dbo].[vspWFValidateStepStatus] TO [public]
GO
