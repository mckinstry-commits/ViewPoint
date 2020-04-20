SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.vspJCLiabTemplValForCopy    Script Date: 8/28/99 9:32:58 AM ******/
CREATE  proc [dbo].[vspJCLiabTemplValForCopy]
/***********************************************************
* CREATED BY:	GF 06/23/2009 - issue #132119
* MODIFIED By:
*
* USAGE:
* Validates destination JC liability template for copy program.
* An error is returned if any of the following occurs:
* no rate company or template passed.
* liability template must not exist for destination company.
*
* INPUT PARAMETERS
* JCCo   Destination JC Company to validate against
* LiabTemplate  Destination liability template to validate
*
* OUTPUT PARAMETERS
* @desc		
* @msg      error message if error occurs
*
* RETURN VALUE
*   0         success
*   1         Failure
*****************************************************/
(@jcco bCompany = 0, @liabtemplate smallint = null,
 @msg varchar(255) = null output)
as
set nocount on   

declare @rcode int

set @rcode = 0

if @jcco is null
	begin
	select @msg = 'Missing JC Company!', @rcode = 1
	goto bspexit
	end

if @liabtemplate is null
	begin
	select @msg = 'Missing Liability Template!', @rcode = 1
	goto bspexit
	end

---- validate destination template must not exist
if exists(select top 1 1 from dbo.JCTH where JCCo=@jcco and LiabTemplate=@liabtemplate)
	begin
	select @msg = 'Invalid liability template, already exists in destinatiion company', @rcode = 1
	goto bspexit
	end

	
bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJCLiabTemplValForCopy] TO [public]
GO
