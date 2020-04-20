SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspPMStatusCodeVal    Script Date: 8/28/99 9:35:19 AM ******/
CREATE    proc [dbo].[bspPMStatusCodeValFinal]
/*************************************
* CREATED BY:
* LAST MODIFIED:	GF 06/26/2009 - issue #134018 - check active all forms flag
*					GF 07/15/2010 - issue #140183 - active all 'N' and document category 'PCO' is valid
*
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
*
*	1 and error message
**************************************/
(@status bStatus, @codetype varchar(1)=null output, @msg varchar(255) output)
as
set nocount on

declare @rcode int, @activeallyn varchar(1), @DocCat varchar(10)

set @rcode = 0

if @status is null
	begin
	select @msg = 'Missing Status!', @rcode = 1
	goto bspexit
	end

---- check PMSC
select @codetype=CodeType, @msg = Description, @activeallyn = ActiveAllYN,
		@DocCat = DocCat
from dbo.PMSC where Status = @status
if @@rowcount = 0
	begin
	select @msg = 'PM Status ' + isnull(@status,'') + ' not on file!', @rcode = 1
	goto bspexit
	end

---- must be a final status type
If @codetype <> 'F' 
	begin
	select @msg = 'Code Type must be Final', @rcode = 1
	goto bspexit
	end

---- #140183
---- if active for all then a valid status
if isnull(@activeallyn,'N') = 'Y'
	begin
	goto bspexit
	end
else
	begin
	---- if not active for all a document category must be assigned.
	if isnull(@DocCat,'') = ''
		begin
		select @msg = 'Invalid Status Code. Document Category has not been assigned.', @rcode = 1
		goto bspexit
		end
	---- if not active for all the document category must be assigned to 'PCO'
	if @DocCat <> 'PCO'
		begin
		select @msg = 'Invalid Status Code. When not active for all forms must be assigned to Document Category (PCO).', @rcode = 1
		goto bspexit
		end
	end
	
------ must be active for all forms
--if isnull(@activeallyn, 'Y') = 'N' and isnull(@DocCat,'PCO') <> 'PCO'
--	begin
--	select @msg = 'Status Code must be active for all forms to use as Default Final Status', @rcode = 1
--	end
---- #140183

bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMStatusCodeValFinal] TO [public]
GO
