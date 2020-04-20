SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspGLClosedMthSubVal    Script Date: 8/28/99 9:34:42 AM ******/
CREATE  procedure [dbo].[bspARGLClosedMthSubVal]
/******************************************************
* CREATED: TJL 04/22/04 - Issue #25098
* Modified: GG 02/22/08 - #120107 - separate sub ledger close - use AR close month
*
* USAGE:
* 	Validates that a month has been closed in AR when purging AR invoices
*
* INPUTS:
* 	@arco		AR Company #
*	@mth		Month requiring validation
*
* OUTPUTS:
*	@msg		Error message
*
* Return Code:
* 	0 if successfull
*	1 and error msg if error
*******************************************************/
   
 @arco bCompany, @mth bMonth, @msg varchar(60) output
   
as 
set nocount on

declare @lastmtharclsd bMonth, @glco bCompany, @rcode int

select @rcode = 0

/* Get ARCO.GLCo */
select @glco = GLCo
from dbo.bARCO (nolock)
where ARCo = @arco
if @glco is null
	begin
	select @msg = 'GL Company in AR Company setup is missing!', @rcode = 1
	goto bspexit
	end
   
/* Check GL Company - get info */
select @lastmtharclsd = LastMthARClsd -- #120107 - use AR close month
from dbo.bGLCO (nolock)
where GLCo = @glco
if @@rowcount = 0
	begin
	select @msg = 'Not a valid GL Company!', @rcode = 1
	goto bspexit
	end
   
/* Check if Month is open */
if @mth > @lastmtharclsd
	begin
	select @msg = char(13) + 'Month must be closed!', @rcode=1
	goto bspexit
	end
   	
bspexit:
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspARGLClosedMthSubVal] TO [public]
GO
