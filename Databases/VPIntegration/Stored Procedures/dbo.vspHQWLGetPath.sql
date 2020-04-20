SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspHQWLGetPath    Script Date: 01/17/2007 ******/
CREATE  proc [dbo].[vspHQWLGetPath]
/*************************************
 * Created By:	GF 01/17/2007 6.x
 * Modified by: JVH 3/23/2010 - Added the template type, file type paramter and word Table index parameter
 *				GF 05/18/2010 - issue #139659 HQWD.CreateFileType expanded to 4 characters.
 *				GPT 03/28/2011 - Added autoResponse output parameter. TK-03252
 *
 *
 * called from PM forms using document tools to get lcation path for document template
 *
 * Pass:
 * TemplateName		PM Document Template Name
 *
 * Success returns:
 *	0 and location path from HQWL
 *
 * Error returns:
 * 
 *	1 and error message
 **************************************/
(@templatename bReportTitle, @location varchar(10) = null output,
 @path varchar(150) = null output, @filename varchar(100) = null output,
 @templateType varchar(10) = null output, @createFileType varchar(4) = null output,
 @autoResponse varchar(1) = null output, @wordTable int = null output, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @msg = ''

---- get location path and file name
if isnull(@templatename,'') <> ''
	begin
	select @filename=d.FileName, @location=d.Location, @path=l.Path, @templateType = TemplateType, @createFileType = CreateFileType, @autoResponse = AutoResponse, @wordTable = WordTable
	from HQWD d with (nolock)
	left join HQWL l with (nolock) on d.Location=l.Location
	where d.TemplateName=@templatename
	if @@rowcount = 0
		begin
		select @msg = 'Invalid Template Name.', @rcode = 1
		goto bspexit
		end
	if isnull(@location,'') = ''
		begin
		select @msg = 'Missing document location for template.', @rcode = 1
		goto bspexit
		end
	end


bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHQWLGetPath] TO [public]
GO
