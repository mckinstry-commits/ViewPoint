SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspCMACLoadProc]
/************************************************************************
* CREATED:	mh 6/21/2005    
* MODIFIED: GG 07/19/07 - added CM Co# validation   
*
* Usage:
*    Load procedure for CM Accounts form
*    
*           
* Inputs:
*	@cmco		CM Company #
*
* Outputs:
*	@glco		GL Company # 
*	@msg		Error message if failure 
*
* Return code:
*	0 = success, 1 = failure 
*
*************************************************************************/
        
    (@cmco bCompany = null, @glco bCompany output, @msg varchar(80) = '' output)

as
set nocount on

declare @rcode int

select @rcode = 0

--validate CM Co# and get GL Co#
select @glco = GLCo from dbo.CMCO (nolock) where CMCo = @cmco
if @@rowcount = 0
	begin
	select @msg = 'Company # ' + convert(varchar,@cmco) + ' not setup in CM!', @rcode = 1
	goto vspexit
	end

if @glco is null
	begin
	select @msg = 'GL Company not setup in CM Company Parameters', @rcode = 1
	goto vspexit
	end

vspexit:
     return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspCMACLoadProc] TO [public]
GO
