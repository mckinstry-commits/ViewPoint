SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspHQBatchMonthVal]
/***********************************************************************************************
* Created: 08/06/97
* Modified: GG 07/01/99
*			RM 02/13/04 = #23061, Add isnulls to all concatenated strings
*			GG 02/22/08 - #120107 - separate sub ledger close
*
* Usage:
*	Called from Batch Selection form to validate a Batch Month.
*
* Inputs:
*	@glco		GL Co#
*	@mth		Batch Month
*	@source		Batch Source
*
* Outputs:
*	@msg		Error message if invalid
*
* Return Code:
*	@rcode		0 = success, 1 = error
*
*********************************************************************************************/
	@glco bCompany = null, @mth bMonth = null, @source bSource = null, @msg varchar(60) output
as
set nocount on

declare @lastmthapclsd bMonth, @lastmtharclsd bMonth, @lastmthsubclsd bMonth, @lastmthglclsd bMonth,
	@maxopen tinyint, @beginmth bMonth,	@endmth bMonth, @clsdmth bMonth, @rcode int

select @rcode = 0

-- check GL Company - get info
select @lastmthsubclsd = LastMthSubClsd, @lastmthglclsd = LastMthGLClsd, @maxopen = MaxOpen,
	@lastmthapclsd = LastMthAPClsd, @lastmtharclsd = LastMthARClsd
from dbo.bGLCO (nolock)
where GLCo = @glco
if @@rowcount = 0
	begin
	select @msg = 'Invalid GL Company!', @rcode = 1
	goto bspexit
	end
	   
-- set ending month to last mth closed in subledgers + max # of open mths
select @endmth = dateadd(month, @maxopen, @lastmthsubclsd)
   
-- set beginning month based on source
select @clsdmth = @lastmthsubclsd	-- default to Sub Ledgers
if @source like 'AP%' or @source in ('MS MatlPay', 'MS HaulPay') select @clsdmth = @lastmthapclsd
if @source like 'AR%' or @source like 'JB%' or @source = 'MS Invoice' select @clsdmth = @lastmtharclsd
if @source like 'GL%' select @clsdmth = @lastmthglclsd

select @beginmth = dateadd(month, 1, @clsdmth) 

-- validate month
if @mth < @beginmth or @mth > @endmth
	begin
	select @msg = 'Month must be between ' + isnull(substring(convert(varchar(8),@beginmth,1),1,3),'')
       + isnull(substring(convert(varchar(8), @beginmth, 1),7,2),'') + ' and '
       + isnull(substring(convert(varchar(8),@endmth,1),1,3),'') + isnull(substring(convert(varchar(8), @endmth, 1),7,2),''), @rcode = 1
   goto bspexit
   end

-- make sure Fiscal Year has been setup for this month
if not exists(select 1 from bGLFY with (nolock) where GLCo = @glco and BeginMth <= @mth and FYEMO >= @mth)
	begin
	select @msg = 'Must first add a Fiscal Year in General Ledger.', @rcode = 1
	goto bspexit
	end
   
bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspHQBatchMonthVal] TO [public]
GO
