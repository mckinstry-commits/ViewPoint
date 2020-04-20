SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspCMBatchProcessLoadProc]
/************************************************************************
* CREATED:	mh 9/8/2005    
* MODIFIED: GG 07/19/07 - added CM Co# validation   
*			TRL 02/20/08 - Issue 21452
*
* Usage:
*	Load procedure for CMBatchProcess    
*    
* Inputs:
*	@co			CM Co#
*
* Outputs:
*	@jrnldesc		GL Journal and its title
*	@glintlvl		GL Interface Level
*	@glco			GL Co#
*	@msg			Error message if failure
*         
* Return code:
*	0 = success, 1 = failure
*
*************************************************************************/
	
    (@co bCompany = null, @jrnldesc varchar(35) output, @glintlvl varchar(15) output,
	 @glco bCompany output,@attachbatchreports bYN output,	@msg varchar(80) = '' output)

as
set nocount on

declare @rcode int, @jrnl bJrnl, @desc bDesc

select @rcode = 0

select @jrnl = Jrnl, @glco = GLCo, 
	@glintlvl = case GLInterfaceLvl
				when 0 then 'No Update'
				when 1 then 'Summary' 
				when 2 then 'Detail'
				else 'Invalid' end,
	@attachbatchreports = IsNull(AttachBatchReportsYN,'N')
from dbo.CMCO (nolock) where CMCo = @co
if @@rowcount = 0
	begin
	select @msg = 'Company # ' + convert(varchar,@co) + ' not setup in CM!', @rcode = 1
	goto vspexit
	end

-- get GL Journal description
select @desc = Description
from dbo.GLJR (nolock)
where GLCo = @glco and Jrnl = @jrnl
if @@rowcount = 0
	begin
	select @msg = 'Invalid GL Co# and Journal', @rcode = 1
	goto vspexit
	end

select @jrnldesc = @jrnl + ' - ' + @desc	-- combine journal and description for ourput

vspexit:
     return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspCMBatchProcessLoadProc] TO [public]
GO
