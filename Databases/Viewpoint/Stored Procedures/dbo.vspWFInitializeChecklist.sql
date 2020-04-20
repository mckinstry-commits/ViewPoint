SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*****************************************************
* Author:		CC
* Create date:  1/3/2008
* Modified:		CC 06/09/2008 - Changed date insert to trim time to 00:00:00
*				CC 07/30/2008 - Issue #129227 - Remove @EnforceOrder from the dynamic sql
*				CC 08/26/2008 - Issue #129564 - Change email notification information\
*				JVH 06/23/2009 - Issue #130980 - Increase size of template name
* Description:	This procedure facilitates creation of a new checklist from an existing checklist or template
*
*	Inputs:
*	@OldCompany			Company where the checklist is located 
*	@OldName			Current checklist or template name
*	@SourceType			If the item source is a checklist or template
*	@Status				Initial status to assign to the new checklist
*	@Company			Destination company to put the checklist into
*	@Name				Name of the new checklist
*	@EnforceOrder		Set enforce order on the new checklist
*	@UseEmail			Set use email on the new checklist
*	@IsPrivate			Set is private on the new checklist
*	@AssignedTo			Set all tasks/steps assigned to this parameter
*	@SendNotification	Sends notifications to users that they can start work on items
*
*	Outputs:
*		@msg returns error message if any
*
*****************************************************/

CREATE PROCEDURE [dbo].[vspWFInitializeChecklist] 
	-- Add the parameters for the stored procedure here
	@OldCompany int = null,
	@OldName varchar(60) = null,
	@SourceType Varchar(1) = null,
	@Status int = null,
	@Company bCompany = null,
	@Name varchar(20) = null,
	@EnforceOrder bYN = null,
	@UseEmail bYN = null,
	@IsPrivate bYN = null,
	@AssignedTo bVPUserName = null,
	@SendNotification bYN = null,
	@msg varchar(255) = null output
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

declare @rcode int
set @rcode = 0 
declare @Sendrcode int,
@Sendmsg varchar(256),
@CRLF char(2)

SET @CRLF = Char(13) + Char(10)

if @SourceType = 'T'
BEGIN
BEGIN TRANSACTION
Begin Try
--copy template into checklist table
DECLARE	@return_value int,
		@Columns varchar(max),
		@sql varchar(max)

EXEC	@return_value = [dbo].[vspWFGetColumns]
		@TableName = N'WFChecklists',
		@MaxCol = 'UniqueAttchID',
		@Columns = @Columns OUTPUT

	set @sql = 'insert into WFChecklists (Company,Checklist,[Status],[Description],ReqCompletion,DateCompleted,EnforceOrder,UseEmail,IsPrivate,AddedBy,AddedOn,ChangedBy,ChangedOn,Notes,UniqueAttchID ' + isnull(@Columns,'') + ')
		select ''' + cast(@Company as varchar(3)) + ''', ''' + @Name + ''', null, t.Description, null, null, 
				t.EnforceOrder, ''' + @UseEmail + ''', ''' + @IsPrivate + ''', null, null, 
				null, null, cast(t.Notes as varchar(max)), t.UniqueAttchID ' + isnull(@Columns,'') + 
		' from WFTemplates t
		where t.Template = ''' + @OldName + ''''
exec(@sql)

EXEC	@return_value = [dbo].[vspWFGetColumns]
		@TableName = N'WFChecklistsTasks',
		@MaxCol = 'UniqueAttchID',
		@Columns = @Columns OUTPUT
--copy template tasks into checklist tasks
set @sql =	'insert into WFChecklistTasks (Task,Company,Checklist,Summary,IsTaskRequired,UseEmail,[Status],[Description],TaskType,VPName,AssignedTo,AssignedOn,DueDate,CompletedBy,CompletedOn,AddedBy,AddedOn,ChangedBy,ChangedOn,Notes,ReportID,UniqueAttchID ' + isnull(@Columns,'') + ')
		select t.Task, ''' + cast(@Company as varchar(3)) + ''', ''' + @Name + ''',t.Summary, t.IsTaskRequired, t.UseEmail, 
				''' + cast(@Status as varchar(max))+ ''', t.Description, t.TaskType, t.VPName, ''' + isnull(@AssignedTo,'') + ''', 
				CASE ''' + isnull(@AssignedTo,'') + '''
					WHEN '''' then null
					ELSE CAST(CONVERT(VARCHAR(50), GETDATE(), 101) AS DATETIME)
				END,
				null, null, null, null, null, null, null, cast(t.Notes as varchar(max)), t.ReportID, t.UniqueAttchID ' + isnull(@Columns,'') + 
		' from WFTemplateTasks t
		where t.Template = ''' + @OldName + ''''
exec (@sql)

EXEC	@return_value = [dbo].[vspWFGetColumns]
		@TableName = N'WFChecklistSteps',
		@MaxCol = 'UniqueAttchID',
		@Columns = @Columns OUTPUT
--copy template steps into checklist steps
set @sql =	'insert into WFChecklistSteps (Step,Task,Company,Checklist,Summary,IsStepRequired,UseEmail,[Status],[Description],StepType,VPName,AssignedTo,AssignedOn,DueDate,CompletedBy,CompletedOn,AddedBy,AddedOn,ChangedBy,ChangedOn,Notes,ReportID,UniqueAttchID ' + isnull(@Columns,'') + ')
		select s.Step, s.Task, ''' + cast(@Company as varchar(3)) + ''', ''' + @Name + ''', s.Summary, s.IsStepRequired, s.UseEmail, ''' + cast(@Status as varchar(max))+ ''', s.Description, s.StepType, s.VPName, ''' + isnull(@AssignedTo,'') + ''',
				CASE ''' + isnull(@AssignedTo,'') + '''
					WHEN '''' then null
					ELSE CAST(CONVERT(VARCHAR(50), GETDATE(), 101) AS DATETIME)
				END,
				null, null, null, null, null, null, null, cast(s.Notes as varchar(max)), s.ReportID, s.UniqueAttchID ' + isnull(@Columns,'') + 
		' from WFTemplateSteps s
		inner join WFTemplateTasks t on s.Task = t.Task and t.Template = ''' + @OldName + ''' and s.Template = t.Template'
exec (@sql)

	IF @SendNotification = 'Y'
		BEGIN
	declare @emailFrom varchar(55)
	select @emailFrom = isnull([Value], 'viewpointcs') from bWDSettings where Setting = 'FromAddress'
		insert into vMailQueue ([To], CC, BCC, [From], [Subject], Body, Source)
			select isnull(up.EMail,''), '', '', @emailFrom as [From],
					CASE WFTasklist.[Type]
						WHEN 'Task' THEN 'New Checklist Task: '
						WHEN 'Step' THEN 'New Checklist Step: ' 
					END
					+ WFTasklist.Summary + ' has been assigned to you'  AS [Subject], 
					CASE WFTasklist.[Type]
						WHEN 'Task' THEN 'You have been assigned to task ' + CAST(WFTasklist.Task AS VARCHAR(5)) + WFTasklist.Summary + ' on Checklist: ' + WFTasklist.Checklist + '.'
						WHEN 'Step' THEN 'You have been assigned to task ' + CAST(WFTasklist.Task AS VARCHAR(5)) + ', step ' +  CAST(WFTasklist.Step AS VARCHAR(5)) + ' ' + WFTasklist.Summary + ' on Checklist: ' + WFTasklist.Checklist + '.'
					END
					AS [Body]
					,'Workflow'
		from WFTasklist
		inner join DDUP up on WFTasklist.AssignedTo = up.VPUserName
		where Company = @Company and Checklist = @Name
	end
End Try
Begin Catch
IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
	select @msg = left('Error Number: ' + cast(ERROR_NUMBER() as varchar(max)) + ' Line: '+ cast(ERROR_LINE() as varchar(max)) + ' Message: ' + ERROR_MESSAGE(),255)
	set @rcode = 1
	return @rcode 
End Catch

IF @@TRANCOUNT > 0
	COMMIT TRANSACTION;
	set @rcode = 0
	return @rcode 
END

if @SourceType = 'C'
BEGIN
Begin Transaction
Begin Try
EXEC	@return_value = [dbo].[vspWFGetColumns]
		@TableName = N'WFChecklists',
		@MaxCol = 'UniqueAttchID',
		@Columns = @Columns OUTPUT
set @sql =	'insert into WFChecklists (Company,Checklist,[Status],[Description],ReqCompletion,DateCompleted,EnforceOrder,UseEmail,IsPrivate,AddedBy,AddedOn,ChangedBy,ChangedOn,Notes,UniqueAttchID ' + isnull(@Columns,'') + ')
		select ''' + cast(@Company as varchar(3)) + ''', ''' + @Name + ''', null, c.Description, null, null, 
				c.EnforceOrder,''' + @UseEmail + ''', ''' + @IsPrivate +''', null, null, 
				null, null, cast(c.Notes as varchar(max)),c.UniqueAttchID ' + isnull(@Columns,'') + 
		'from WFChecklists c
		where c.Checklist = ''' + @OldName + ''' and c.Company = ''' + cast(@OldCompany as varchar(3))+ ''''
exec (@sql)

--copy checklist tasks into checklist tasks
EXEC	@return_value = [dbo].[vspWFGetColumns]
		@TableName = N'WFChecklistTasks',
		@MaxCol = 'UniqueAttchID',
		@Columns = @Columns OUTPUT
set @sql =	'insert into WFChecklistTasks (Task,Company,Checklist,Summary,IsTaskRequired,UseEmail,[Status],[Description],TaskType,VPName,AssignedTo,AssignedOn,DueDate,CompletedBy,CompletedOn,AddedBy,AddedOn,ChangedBy,ChangedOn,Notes,ReportID,UniqueAttchID ' + isnull(@Columns,'') + ')
		select t.Task, ''' + cast(@Company as varchar(3)) + ''', ''' + @Name + ''', t.Summary, t.IsTaskRequired, t.UseEmail, 
				''' + cast(@Status as varchar(max))+ ''', t.Description, t.TaskType, t.VPName, 
				CASE ''' + isnull(@AssignedTo,'') +'''
					WHEN '''' then t.AssignedTo
					ELSE ''' + isnull(@AssignedTo,'') + '''
				END, 
				CASE isnull(t.AssignedTo,'''') 
					WHEN '''' then null
					ELSE CAST(CONVERT(VARCHAR(50), GETDATE(), 101) AS DATETIME)
				END,
				null, null, null, null, null, null, null, cast(t.Notes as varchar(max)), t.ReportID, t.UniqueAttchID ' + isnull(@Columns,'') + 
		'from WFChecklistTasks t
		where t.Checklist = ''' + @OldName + ''' and t.Company = ''' + cast(@OldCompany as varchar(3))+ ''''
exec (@sql)

--copy checklist steps into checklist steps
EXEC	@return_value = [dbo].[vspWFGetColumns]
		@TableName = N'WFChecklistSteps',
		@MaxCol = 'UniqueAttchID',
		@Columns = @Columns OUTPUT
set @sql = 	'insert into WFChecklistSteps (Step,Task,Company,Checklist,Summary,IsStepRequired,UseEmail,[Status],[Description],StepType,VPName,AssignedTo,AssignedOn,DueDate,CompletedBy,CompletedOn,AddedBy,AddedOn,ChangedBy,ChangedOn,Notes,ReportID, UniqueAttchID ' + isnull(@Columns,'') + ')
		select s.Step, s.Task,''' + cast(@Company as varchar(3)) + ''', ''' + @Name + ''', s.Summary, s.IsStepRequired, s.UseEmail, ''' + cast(@Status as varchar(max))+ ''', s.Description, s.StepType, s.VPName, 
				CASE ''' + isnull(@AssignedTo, '') + '''
					WHEN '''' then s.AssignedTo
					ELSE ''' + isnull(@AssignedTo,'')  + '''
				END, 
				CASE isnull(t.AssignedTo,'''') 
					WHEN '''' then null
					ELSE CAST(CONVERT(VARCHAR(50), GETDATE(), 101) AS DATETIME)
				END,
				null, null, null, null, null, null, null, cast(s.Notes as varchar(max)), s.ReportID, s.UniqueAttchID ' + isnull(@Columns,'') + 
		'from WFChecklistSteps s
		inner join WFChecklistTasks t on s.Task = t.Task and t.Checklist = ''' + @OldName + ''' and s.Checklist = t.Checklist 
										  and t.Company = ''' + cast(@OldCompany as varchar(3))+ ''' and s.Company = t.Company'
exec (@sql)

	IF @SendNotification = 'Y'
		BEGIN
		select @emailFrom = isnull([Value], 'viewpointcs') from bWDSettings where Setting = 'FromAddress'
		insert into vMailQueue ([To], CC, BCC, [From], [Subject], Body, Source)
			select isnull(up.EMail,''), '', '', @emailFrom as [From],
					CASE WFTasklist.[Type]
						WHEN 'Task' THEN 'New Checklist Task: '
						WHEN 'Step' THEN 'New Checklist Step: ' 
					END
					+ WFTasklist.Summary + ' has been assigned to you'  AS [Subject], 
					CASE WFTasklist.[Type]
						WHEN 'Task' THEN 'You have been assigned to task ' + CAST(WFTasklist.Task AS VARCHAR(5)) + WFTasklist.Summary + ' on Checklist: ' + WFTasklist.Checklist + '.'
						WHEN 'Step' THEN 'You have been assigned to task ' + CAST(WFTasklist.Task AS VARCHAR(5)) + ', step ' +  CAST(WFTasklist.Step AS VARCHAR(5)) + ' ' + WFTasklist.Summary + ' on Checklist: ' + WFTasklist.Checklist + '.'
					END
					AS [Body]
					,'Workflow'
		from WFTasklist
		inner join DDUP up on WFTasklist.AssignedTo = up.VPUserName
		where Company = @Company and Checklist = @Name
	end
		End Try
Begin Catch
IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION;
	select @msg = left('Error Number: ' + cast(ERROR_NUMBER() as varchar(max)) + ' Line: '+ cast(ERROR_LINE() as varchar(max)) + ' Message: ' + ERROR_MESSAGE(),255)
	set @rcode = 1
	return @rcode 
End Catch

IF @@TRANCOUNT > 0
	COMMIT TRANSACTION;
	set @rcode = 0
	return @rcode 
END

END


GO
GRANT EXECUTE ON  [dbo].[vspWFInitializeChecklist] TO [public]
GO
