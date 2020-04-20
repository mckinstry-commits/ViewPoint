IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[vspPMDocSelectListFill]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[vspPMDocSelectListFill]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/****************************************************************************/
CREATE  proc [dbo].[vspPMDocSelectListFill]
/****************************************************************************
 * Created By:	GF 01/05/2007 6.x
 * Modified By:	SCOTTP 02/05/2014 TFS-70346 Return field stores the default the edit option checkbox in the SendDocument form
 *				SCOTTP 02/21/2014 TFS-74937 Merge C&S Edit Workflow modifications from 6.8
 *
 *
 * USAGE:
 * Returns a resultset of PM document template names for the template type.
 * Used in the PMDocSelection form to populate list view.
 *
 * INPUT PARAMETERS:
 * Template Type		Document template type
 *
 * OUTPUT PARAMETERS:
 *
 *
 * RETURN VALUE:
 * 	0 	    Success
 *	1 & message Failure
 *
 *****************************************************************************/
(@templatetype varchar(10) = null, @activeonly bYN = 'N', @submittaltype varchar(1) = null,
 @excludetemplate bReportTitle = null, @editflag bYN = 'N')
as
set nocount on

declare @sql varchar(1000)

if isnull(@excludetemplate,'') <> ''
	begin
	select @excludetemplate = rtrim(@excludetemplate)
	end

---- return resultset of HQWD Template Names for Template Type
--select  'TypeOfDoc' = 'Word', 'Template' = a.TemplateName
--	select 'Template' = a.TemplateName
--	FROM dbo.HQWD a left join dbo.HQWL l on l.Location=a.Location
--	where a.TemplateType=@templatetype and a.Active='Y'
--	order by a.TemplateName
if @editflag = 'Y'
	begin
	select @sql = 'select ' + char(39) + 'Template' + char(39) + ' = a.TemplateName, a.EditDocDefault from dbo.HQWD a'
	select @sql = @sql + ' where a.TemplateType = ' + char(39) + @templatetype + char(39)
	if isnull(@activeonly,'N') = 'Y'
		begin
		select @sql = @sql + ' and a.Active = ' + char(39) + 'Y' + char(39)
		end
	if isnull(@submittaltype,'') <> ''
		begin
		select @sql = @sql + ' and a.SubmitType = ' + char(39) + @submittaltype + char(39)
		end
	if isnull(@excludetemplate,'') <> ''
		begin
		select @sql = @sql + ' and rtrim(a.TemplateName) <> ' + char(39) + @excludetemplate + char(39)
		end

	select @sql = @sql + ' order by a.TemplateName'
	end
else
	begin
	if @templatetype <> 'SUB'
		begin
		select @sql = 'select ' + char(39) + 'Template' + char(39) + ' = a.TemplateName, a.EditDocDefault from dbo.HQWD a'
		select @sql = @sql + ' where a.TemplateType = ' + char(39) + @templatetype + char(39)
		if isnull(@activeonly,'N') = 'Y'
			begin
			select @sql = @sql + ' and a.Active = ' + char(39) + 'Y' + char(39)
			end
		if isnull(@submittaltype,'') <> ''
			begin
			select @sql = @sql + ' and a.SubmitType = ' + char(39) + @submittaltype + char(39)
			end
		if isnull(@excludetemplate,'') <> ''
			begin
			select @sql = @sql + ' and rtrim(a.TemplateName) <> ' + char(39) + @excludetemplate + char(39)
			end

		select @sql = @sql + ' order by a.TemplateName'
		end
	else
		begin
		select @sql = 'select ' + char(39) + 'Template' + char(39) + ' = a.TemplateName,a.EditDocDefault from dbo.HQWD a'
		select @sql = @sql + ' where a.TemplateType in (' + char(39) + 'SUB' + char(39) + ',' + char(39) + 'SUBITEM' + char(39) + ')'
		if isnull(@activeonly,'N') = 'Y'
			begin
			select @sql = @sql + ' and a.Active = ' + char(39) + 'Y' + char(39)
			end
		if isnull(@submittaltype,'') <> ''
			begin
			select @sql = @sql + ' and a.SubmitType = ' + char(39) + @submittaltype + char(39)
			end
		if isnull(@excludetemplate,'') <> ''
			begin
			select @sql = @sql + ' and rtrim(a.TemplateName) <> ' + char(39) + @excludetemplate + char(39)
			end

		select @sql = @sql + ' order by a.TemplateName'
		end
	end


exec (@sql)








----bspexit:
----   	return @rcode


GO


