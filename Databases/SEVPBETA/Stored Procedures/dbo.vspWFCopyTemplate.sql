SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***********************************************************
* CREATED BY:  Charles Courchaine 1/7/2008
* MODIFIED By : JVH		6/23/09 Issue 130980 - increased @TemplateSource and @TemplateDestination to VARCHAR(60)
*
* USAGE:
* 	This procedure copies a given template
*
* INPUT PARAMETERS
*	@TemplateSource			Name of the template to copy from
*	@TemplateDestination	Name of the new template to copy into
*   
* OUTPUT PARAMETERS
*   @msg      Error message
*
*****************************************************/
CREATE PROCEDURE [dbo].[vspWFCopyTemplate] 
	-- Add the parameters for the stored procedure here
	@TemplateSource varchar(60) = null,
	@TemplateDestination varchar(60) = null,
	@msg varchar(255) = null output
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

declare @rcode int
set @rcode = 0 

BEGIN TRANSACTION
Begin Try
--copy template
DECLARE	@return_value int,
		@Columns varchar(max),
		@sql varchar(max)

EXEC	@return_value = [dbo].[vspWFGetColumns]
		@TableName = N'WFTemplates',
		@MaxCol = 'UniqueAttchID',
		@Columns = @Columns OUTPUT

set @sql = 'insert into WFTemplates (Template,[Description],Revised,EnforceOrder,UseEmail,IsActive,IsStandard,AddedBy,AddedOn,ChangedBy,ChangedOn,Notes,UniqueAttchID ' + isnull(@Columns,'') + ')
	select ''' + @TemplateDestination + ''', x.[Description], x.Revised, x.EnforceOrder, x.UseEmail, x.IsActive, ''N'', ''' + cast(suser_sname() as varchar(max)) + ''', ''' + cast(getdate() as varchar(max))+ ''', ''' + cast(suser_sname() as varchar(max))+ ''', ''' + cast(getdate() as varchar(max)) + ''', cast(x.Notes as varchar(max)), x.UniqueAttchID ' + isnull(@Columns,'') +
	' from WFTemplates x
	where x.Template = ''' + isnull(@TemplateSource,'') + ''''
exec(@sql)

--copy template tasks 
EXEC	@return_value = [dbo].[vspWFGetColumns]
		@TableName = N'WFTemplateTasks',
		@MaxCol = 'UniqueAttchID',
		@Columns = @Columns OUTPUT

set @sql = 'insert into WFTemplateTasks (Task,Template,Summary,IsTaskRequired,UseEmail,[Description],TaskType,VPName,IsStandard,AddedBy,AddedOn,ChangedBy,ChangedOn,Notes,ReportID,UniqueAttchID ' + isnull(@Columns,'') + ')
	select x.Task, ''' + isnull(@TemplateDestination,'') + ''', x.Summary, x.IsTaskRequired, x.UseEmail, x.[Description], x.TaskType, x.VPName, ''N'', ''' + cast(suser_sname() as varchar(max)) + ''', ''' + cast(getdate() as varchar(max))+ ''', ''' + cast(suser_sname() as varchar(max))+ ''', ''' + cast(getdate() as varchar(max)) + ''', cast(x.Notes as varchar(max)), x.ReportID, x.UniqueAttchID ' + isnull(@Columns,'') +
	'from WFTemplateTasks x
	where x.Template = ''' + isnull(@TemplateSource,'') + ''''
exec (@sql)

--copy template steps 
EXEC	@return_value = [dbo].[vspWFGetColumns]
		@TableName = N'WFTemplateSteps',
		@MaxCol = 'UniqueAttchID',
		@Columns = @Columns OUTPUT


set @sql = 'insert into WFTemplateSteps (Step,Task,Template,Summary,IsStepRequired,UseEmail,[Description],StepType,VPName,IsStandard,AddedBy,AddedOn,ChangedBy,ChangedOn,Notes,ReportID,UniqueAttchID ' + isnull(@Columns,'') + ')
	select s.Step, s.Task, ''' + isnull(@TemplateDestination,'') + ''', s.Summary, s.IsStepRequired, s.UseEmail, s.[Description], s.StepType, s.VPName,''N'', ''' + cast(suser_sname() as varchar(max)) + ''', ''' + cast(getdate() as varchar(max))+ ''', ''' + cast(suser_sname() as varchar(max))+ ''', ''' + cast(getdate() as varchar(max)) + ''', cast(s.Notes as varchar(max)), s.ReportID, s.UniqueAttchID  ' + isnull(@Columns,'') +
	'from WFTemplateSteps s
	inner join WFTemplateTasks t on s.Task = t.Task and t.Template = ''' + isnull(@TemplateSource,'') + ''' and s.Template = t.Template'
exec(@sql)

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

/****** Object:  StoredProcedure [dbo].[vspWFGetChecklistsandTemplates]    Script Date: 01/30/2008 16:08:40 ******/
SET ANSI_NULLS ON

GO
GRANT EXECUTE ON  [dbo].[vspWFCopyTemplate] TO [public]
GO
