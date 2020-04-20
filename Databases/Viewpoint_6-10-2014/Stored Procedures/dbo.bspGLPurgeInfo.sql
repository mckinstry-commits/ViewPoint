SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[bspGLPurgeInfo]
/**********************************************************************
* Created: ?
* Modified: MV 01/31/03 - #20246 dbl quote cleanup.
*			GG 03/07/06 - 6.0 cleanup
*
* Used by GL Purge to get information needed prior to purge
*
* Inputs:
*	@glco			GL Company
*
* Output:
*	@lastmthglclsd 		Last month closed in GL
*	@oldesttrans		Oldest month with GL transactions
*	@lastyrclsd			Last closed fiscal year
*	@oldestsummary		Oldest fiscal year with Account Summary entries
*	@oldestbalances		Oldest fiscal year with Account Balances
*	@errmsg				Error message
*
* Return code:	
*	0 = success, 1 = error
*
**********************************************************************/
   
   	@glco bCompany = null, @lastmthglclsd bMonth output, @oldesttrans bMonth output,
	@lastyrclsd bMonth output, @oldestsummary bMonth output, @oldestbalances bMonth output,
	@errmsg varchar(255) output
   
as
set nocount on
declare @rcode int
   
select @rcode = 0
   
if @glco is null
	begin
   	select @errmsg = 'Missing GL Company!', @rcode = 1
   	goto bspexit
   	end
   
/* get last Month Closed in General Ledger */
select @lastmthglclsd = LastMthGLClsd
from dbo.bGLCO (nolock)
where GLCo = @glco
if @@rowcount = 0
   	begin
   	select @errmsg = 'Invalid GL Company!', @rcode = 1
   	goto bspexit
   	end
   
/* get oldest month with Journal Transactions */
select @oldesttrans = min(Mth)
from dbo.bGLDT (nolock)
where GLCo = @glco
   
/* get last closed Fiscal Year */
select @lastyrclsd = max(FYEMO)
from dbo.bGLFY (nolock)
where GLCo = @glco and FYEMO <= @lastmthglclsd
   
/* get oldest Fiscal Year with Account Summary */
select @oldestsummary = min(FYEMO)
from dbo.bGLFY y (nolock)
join dbo.bGLAS s (nolock) on y.GLCo = s.GLCo
where y.GLCo = @glco and s.Mth >= y.BeginMth and s.Mth <= y.FYEMO
   
/* get oldest Fiscal Year with Account Balances */
select @oldestbalances = min(FYEMO)
from dbo.bGLFY y (nolock)
join dbo.bGLBL b (nolock) on y.GLCo = b.GLCo
where y.GLCo = @glco and b.Mth >= y.BeginMth and b.Mth <= y.FYEMO
   
  
bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspGLPurgeInfo] TO [public]
GO
