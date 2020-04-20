SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspHQGetResponseFields    Script Date: 03/28/2011 ******/
CREATE  proc [dbo].[vspHQGetResponseFields]
/*************************************
 * Created By:	GPT 03/28/2011 
 *
 *
 * called from to get response fields and values for a document template
 *
 * Pass:
 * TemplateName		PM Document Template Name
 *
 * Success returns:
 *	0 and response fields and values
 *
 * Error returns:
 * 
 *	1 and error message
 **************************************/
(@templatename bReportTitle, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @msg = ''

---- get response fields and avlaues
if isnull(@templatename,'') <> ''
	begin
	
	if not exists ( SELECT TOP 1 1 FROM HQWD WHERE TemplateName = @templatename )
		begin
		select @msg = 'Invalid Template Name.', @rcode = 1
		goto bspexit
		end
	
	-- get response fields for templatename
	select r.[TemplateName],r.[DocObject],[ColumnName],r.[ResponseFieldName],r.[Caption],r.[ControlType],r.[ResponseValues],r.[Bookmark],r.[ResponseOrder],r.[KeyID],r.[Visible],r.[ReadOnly]
	from HQDocTemplateResponseField r
	where r.TemplateName=@templatename
	
	-- get responsevalueitems for response value selections
	select distinct r.[ValueCode], r.[DisplayValue], r.[DatabaseValue], r.[Seq]
	from HQResponseValueItem r INNER JOIN
	HQDocTemplateResponseField f ON f.ResponseValues = r.ValueCode 
	where f.TemplateName=@templatename Order By [ValueCode],[Seq]
	
	end
	
bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHQGetResponseFields] TO [public]
GO
