SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspCMSTLoadProc]
/************************************************************************
* CREATED:    mh 6/22/04
* MODIFIED: GG 07/19/07 - added CM Co# validation   
*
* Usage:
*    Load Procedure for CMST (CM Statements)
*    
* Inputs:
*	@cmco		CM Co#
*
* Outputs:
*	@chgbegbal		Allow change to beginning balance flag
*	@msg			Error message if failure
*
* Return code:
*	0 = success, 1 = failure           
*
*************************************************************************/

    (@cmco bCompany = null, @chgbegbal bYN output, @msg varchar(80) = '' output)

as
set nocount on

declare @rcode int

select @rcode = 0

-- validate CM Co# and get 'Change Begin Balance' flag
select @chgbegbal = ChangeBegBal
from dbo.CMCO (nolock)
where CMCo = @cmco
if @@rowcount = 0
	begin
	select @msg = 'Company # ' + convert(varchar,@cmco) + ' not setup in CM!', @rcode = 1
	goto vspexit
	end

vspexit:
     return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspCMSTLoadProc] TO [public]
GO
