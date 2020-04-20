SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspHQWDFileTypeGet    Script Date: 01/17/2007 ******/
CREATE  proc [dbo].[vspHQWDFileTypeGet]
/*************************************
 * Created By:	GF 04/22/2008 6.x
 * Modified by:	GF 05/18/2010 - issue #139659 HQWD.CreateFileType expanded to 4 characters.
 *
 *
 * called from PM Document Create and Send Form to get the HQWD.CreateFileType
 * default value will be 'doc'
 *
 * Pass:
 * TemplateName		PM Document Template Name
 *
 * OUTPUT
 * @createfiletype	HQWD Create File Type option (doc,pdf)
 *
 * Success returns:
 *	0 and no message
 * Error returns:
 *	1 and error message
 **************************************/
(@templatename bReportTitle, @createfiletype varchar(4) = 'doc' output,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0, @msg = '', @createfiletype = 'doc'

---- get create file type option for template
if isnull(@templatename,'') <> ''
	begin
	select @createfiletype=CreateFileType
	from dbo.bHQWD d with (nolock) where d.TemplateName=@templatename
	if @@rowcount = 0
		begin
		select @createfiletype = 'doc'
		goto bspexit
		end
	if isnull(@createfiletype,'') = ''
		begin
		select @createfiletype = 'doc'
		goto bspexit
		end
	end


bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspHQWDFileTypeGet] TO [public]
GO
