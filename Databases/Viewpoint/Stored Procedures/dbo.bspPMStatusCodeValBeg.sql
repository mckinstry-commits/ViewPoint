SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspPMStatusCodeVal    Script Date: 8/28/99 9:35:19 AM ******/
CREATE proc [dbo].[bspPMStatusCodeValBeg]
/*************************************
* CREATED BY:
* LAST MODIFIED:	GF 06/26/2009 - issue #134018 - check active all forms flag
*					GP 06/30/2011 - TK-05540 fixed spelling error in final error message
* 
* validates PM Firm Types
*
* Pass:
*	PM StatusCode
*
* Returns:
*       CodeType
*       Status Description
*
* Success returns:
*	0 and Description from FirmType
*
* Error returns:

*	1 and error message
**************************************/
(@status bStatus, @codetype varchar(1)=null output, @msg varchar(60) output)
as
set nocount on

declare @rcode int, @activeallyn varchar(1)

set @rcode = 0

if @status is null
	begin
	select @msg = 'Missing Status!', @rcode = 1
	goto bspexit
	end

---- check PMSC
select @codetype=CodeType, @msg = Description, @activeallyn = ActiveAllYN
from PMSC with (nolock) where Status = @status
if @@rowcount = 0
	begin
	select @msg = 'PM Status ' + isnull(@status,'') + ' not on file!', @rcode = 1
	end
	
---- must be a begin status type
If @codetype <> 'B' 
	begin
	select @msg = 'Code Type must be Beginning', @rcode = 1
	end
	
---- must be active for all forms
if isnull(@activeallyn, 'Y') = 'N'
	begin
	select @msg = 'Status Code must be active for all forms to use as Default Beginning Status', @rcode = 1
	end



bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMStatusCodeValBeg] TO [public]
GO
