SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*********************************************/
CREATE proc [dbo].[vspPMCTValForStatusCode]
/***********************************************************
* CREATED By:	GF 06/21/2009 - issue #24641
* MODIFIED By:	GP 09/15/2012 - TK-17949 Added validation to not allow SBMTLPCKG use 
*
*
* USAGE:
* validates the PM Document Category assigned in PM Status codes.
* Valid Document Categories in (PMCT).
* When restricted to one category, the status must not be
* used in PM Company Parameters as the begin status or
* the final status default.
*
*
*
*
* INPUT PARAMETERS
* DocCat	PM Document Category to validate
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs otherwise Description
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(@status varchar(6) = null, @activeall varchar(1) = 'Y', @doccat varchar(10) = null,
 @msg varchar(255) output)
as
set nocount on

declare @rcode int

set @rcode = 0

if @status is null
	begin
	select @msg = 'Missing Status Code!', @rcode = 1
	goto bspexit
	end

---- if the use status for all forms is 'Y' then we are done.
if isnull(@activeall,'Y') = 'Y' goto bspexit

---- document category cannot be null
if @doccat is null
	begin
	select @msg = 'Missing Document Category!', @rcode = 1
	goto bspexit
	end

--Cannot use submittal package, only submittals	
IF @doccat = 'SBMTLPCKG'
BEGIN
	SELECT @msg = 'Cannot assign a Status Code to this document category.', @rcode = 1
	GOTO bspexit
END	

---- validate document category
select @msg = Description
from dbo.PMCT with (nolock) where DocCat=@doccat
if @@rowcount = 0
	begin
	select @msg = 'Invalid Document Category.', @rcode = 1
	goto bspexit
	end
	
---- check PM company parameters for use as begin status default
if exists(select top 1 1 from dbo.PMCO where BeginStatus = @status)
	begin
	select @msg = 'Status code is used as default Begin Status in PM Company Parameters. You must remove as default first before restricting to a document category.', @rcode = 1
	goto bspexit
	end

---- check PM company parameters for use as final status default
if exists(select top 1 1 from dbo.PMCO where FinalStatus = @status)
	begin
	select @msg = 'Status code is used as default Final Status in PM Company Parameters. You must remove as default first before restricting to a document category.', @rcode = 1
	goto bspexit
	end




bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMCTValForStatusCode] TO [public]
GO
