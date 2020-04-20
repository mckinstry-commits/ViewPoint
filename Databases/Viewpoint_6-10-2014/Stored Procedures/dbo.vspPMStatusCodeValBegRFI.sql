SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE proc [dbo].[vspPMStatusCodeValBegRFI]
/*************************************
* CREATED BY:		GP 06/30/2011 - TK-05540 Created this from old status code val proc
* LAST MODIFIED:	GF 06/26/2009 - issue #134018 - check active all forms flag
* 
* Validate Beginning Status Code for PM Company Form - Default RFI Beginning Status field.
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
(@status bStatus, @codetype varchar(1) = null output, @msg varchar(60) output)
as
set nocount on

declare @rcode int, @activeallyn varchar(1), @DocCat varchar(10)

set @rcode = 0

if @status is null
begin
	select @msg = 'Missing Status!', @rcode = 1
	goto vspexit
end

--check PMSC
select @codetype=CodeType, @msg = [Description], @activeallyn = ActiveAllYN, @DocCat = DocCat
from dbo.PMSC
where [Status] = @status
if @@rowcount = 0
begin
	select @msg = 'PM Status ' + isnull(@status,'') + ' not on file!', @rcode = 1
	goto vspexit
end
	
--must be a begin status type
if @codetype <> 'B' 
begin
	select @msg = 'Code Type must be Beginning.', @rcode = 1
	goto vspexit
end

--must be doc cat RFI
if isnull(@DocCat,'') <> 'RFI'
begin
	select @msg = 'Document Category must be RFI.', @rcode = 1
	goto vspexit
end
	


vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMStatusCodeValBegRFI] TO [public]
GO
