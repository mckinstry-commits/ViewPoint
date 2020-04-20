SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspHQWDDestVerify]
/*************************************
 * Created By:	GF 02/15/2007 6.x
 * Modified By:
 *
 * verify destination template uniqueness for PM document template copy
 *
 * Pass:
 * TemplateName
 *
 * Success returns:
 *	0
 *
 * Error returns:
 *	1 and error message
 **************************************/
(@templatename bReportTitle = null, @errmsg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0
   
if isnull(@templatename,'') = ''
	begin
	select @errmsg = 'Destination Document Template is required', @rcode=1
	goto bspexit
	end

---- verify destination template does not exists
if exists(select * from HQWD where TemplateName=@templatename)
	begin
	select @errmsg = 'Destination Document Template already exists', @rcode=1
	goto bspexit
	end


bspexit:
	if @rcode<>0 select @errmsg=isnull(@errmsg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQWDDestVerify] TO [public]
GO
