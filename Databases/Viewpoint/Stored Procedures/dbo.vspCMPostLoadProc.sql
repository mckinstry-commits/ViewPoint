SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspCMPostLoadProc]
/************************************************************************
* CREATED:	mh 4/27/06    
* MODIFIED: GG 07/19/07 - added CM Co# validation   
*			CHS	04/22/2011	- TK-04439 added TaxGroup output
*
* Usage:
*	Load procedure for CM Post and Transfer
*    
* Inputs:
*	@cmco		CM Co#
*
* Outputs:
*	@glco		GL Co#
*	@msg		Error message if failure
*	@TaxGroup
*
* Return code:
*	0 = success, 1 = failure           
*
*************************************************************************/
(@cmco bCompany = null, @glco bCompany = null output, 
	@TaxGroup bGroup = null output, @msg varchar(80) = '' output)

as

set nocount on

declare @rcode int

select @rcode = 0

-- validation CM Co# and get GL Co#
select @glco = GLCo, @TaxGroup = TaxGroup
from dbo.CMCO (nolock) 
	join dbo.HQCO (nolock) on HQCO.HQCo = CMCO.CMCo
where CMCo = @cmco

if @@rowcount = 0
	begin
	select @msg = 'Company # ' + convert(varchar,@cmco) + ' not setup in CM!', @rcode = 1
	goto vspexit
	end

vspexit:
     return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspCMPostLoadProc] TO [public]
GO
