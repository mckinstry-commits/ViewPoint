SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspJBHQBatchMonthValStd Script Date: ******/
CREATE procedure [dbo].[vspJBHQBatchMonthValStd]
/***********************************************************************************************
*Created:  TJL  04/27/06 - Issue #28184, 28048, 28228
*Last Revised: GG 02/25/08 - #120107 - separate sub ledger close - use AR month
*
* Usage: Called from JBCompleteBill
*
* Input Params:  JBCo#, Month
*
* Output Params: Error message if invalid
*
* Return Code:  0 if successfull, 1 if error
*********************************************************************************************/
@jbco bCompany = null, @mth bMonth = null, @msg varchar(255) output
as
set nocount on
   
declare @jcarco bCompany, @jcglco bCompany, @arglco bCompany, 
	@JClastmthsubclsd bMonth, @JClastmthglclsd bMonth, @JCmaxopen tinyint,
	@JCbeginmth bMonth, @JCendmth bMonth,
	@ARlastmthsubclsd bMonth, @ARlastmthglclsd bMonth, @ARmaxopen tinyint,
	@ARbeginmth bMonth, @ARendmth bMonth,
	@rcode int, @ARlastmtharclsd bMonth
   
select @rcode = 0

select @jcarco = c.ARCo, @jcglco = c.GLCo, @arglco = a.GLCo
from JCCO c with (nolock)
join ARCO a with (nolock) on a.ARCo = c.ARCo
where c.JCCo = @jbco

/* Get JC & AR GL Company info */
select @JClastmthsubclsd = LastMthSubClsd, @JClastmthglclsd = LastMthGLClsd,
	@JCmaxopen = MaxOpen
from GLCO with (nolock)
where GLCo = @jcglco
if @@rowcount = 0
	begin
	select @msg = 'Invalid JC GL Company!', @rcode = 1
	goto vspexit
	end
   
select @ARlastmthsubclsd = LastMthSubClsd, @ARlastmthglclsd = LastMthGLClsd,
	@ARmaxopen = MaxOpen, @ARlastmtharclsd = LastMthARClsd
from GLCO with (nolock)
where GLCo = @arglco
if @@rowcount = 0
	begin
	select @msg = 'Invalid AR GL Company!', @rcode = 1
	goto vspexit
	end

/* Evaluate JC GL */
/* Set ending month to last mth closed in subledgers + max # of open mths. */
select @JCendmth = dateadd(month, @JCmaxopen, @JClastmthsubclsd)
   
/* Set beginning month. */
select @JCbeginmth = dateadd(month, 1, @JClastmthsubclsd) 

if @mth < @JCbeginmth or @mth > @JCendmth
	begin
	select @msg = 'Invalid JC GLSubLedger Month.  Must be between ' + isnull(substring(convert(varchar(8),@JCbeginmth,1),1,3),'')
       + isnull(substring(convert(varchar(8), @JCbeginmth, 1),7,2),'') + ' and '
       + isnull(substring(convert(varchar(8),@JCendmth,1),1,3),'') + isnull(substring(convert(varchar(8), @JCendmth, 1),7,2),''), @rcode = 1
	goto vspexit
	end
   
/* make sure Fiscal Year has been setup for this month. */
if not exists(select 1 from GLFY with (nolock) where GLCo = @jcglco and BeginMth <= @mth and FYEMO >= @mth)
	begin
	select @msg = 'Must first add a Fiscal Year in General Ledger for this JC GL Company.', @rcode = 1
	goto vspexit
	end
  
/* Evaluate AR GL */
/* Set ending month to last mth closed in subledgers + max # of open mths. */
select @ARendmth = dateadd(month, @ARmaxopen, @ARlastmthsubclsd)
   
/* Set beginning month. */
select @ARbeginmth = dateadd(month, 1, @ARlastmtharclsd) -- #120107 - use AR month

if @mth < @ARbeginmth or @mth > @ARendmth
	begin
	select @msg = 'Invalid AR GLSubLedger Month.  Month must be between ' + isnull(substring(convert(varchar(8),@ARbeginmth,1),1,3),'')
       + isnull(substring(convert(varchar(8), @ARbeginmth, 1),7,2),'') + ' and '
       + isnull(substring(convert(varchar(8),@ARendmth,1),1,3),'') + isnull(substring(convert(varchar(8), @ARendmth, 1),7,2),''), @rcode = 1
	goto vspexit
	end
   
/* make sure Fiscal Year has been setup for this month. */
if not exists(select 1 from GLFY with (nolock) where GLCo = @arglco and BeginMth <= @mth and FYEMO >= @mth)
	begin
	select @msg = 'Must first add a Fiscal Year in General Ledger for this AR GL Company.', @rcode = 1
	goto vspexit
	end  
   
vspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJBHQBatchMonthValStd] TO [public]
GO
