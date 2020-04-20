SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspHQWDVal]
/***********************************************************
 * CREATED By:	GF 02/15/2007
 * MODIFIED By:
 *
 *
 * USAGE:
 * validates HQ Document Template
 *
 * PASS:
 * TemplateName
 *
 * RETURNS:
 * Location
 * FileName
 * ErrMsg if any
 * 
 * OUTPUT PARAMETERS
 * @msg     Error message if invalid, 
 * RETURN VALUE
 *   0 Success
 *   1 fail
 *****************************************************/ 
(@templatename bReportTitle, @srclocation varchar(10) = null output, @srcfilename varchar(60) = null output,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0

if @templatename is null
   	begin
   	select @msg = 'Missing Document Template!', @rcode = 1
   	goto bspexit
   	end

---- validate template name
select @srclocation=Location, @srcfilename=FileName
from HQWD with (nolock) where TemplateName=@templatename
if @@rowcount = 0
   	begin
   	select @msg = 'Invalid Document Template', @rcode = 1
   	goto bspexit
   	end



bspexit:
	if @rcode<>0 select @msg=isnull(@msg,'')
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQWDVal] TO [public]
GO
