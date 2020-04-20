SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   proc [dbo].[bspPRAPUpdateMonthVal]
/***********************************************************
* CREATED: GG 02/23/01
* MODIFIED: GG 03/29/01 - added check for valid bGLFY entry
*			EN 10/7/02 - issue 18877 change double quotes to single
*			GG 02/22/08 - #120107 - separate sub ledger close, use last mth AP closed
*
* Usage:
*  Called by the PR AP Update form to validate the AP Expense Mth.
*  Dedn/liabs must be expensed in a month equal to or later than paid.
*
* Input params:
*	@prco		PR company
*	@prgroup 	PR Group
* 	@prenddate	PR Ending Date
*	@expmth		Expense Month to validate
*
* Output params:
*	@msg		error message
*
* Return code:
*	0 = success, 1 = failure
************************************************************/
       (@prco bCompany = null, @prgroup bGroup = null, @prenddate bDate = null,
        @expmth bMonth = null, @msg varchar(255) = null output)
as
set nocount on

declare @rcode int, @apco bCompany, @glco bCompany, @lastmthsubclsd bMonth, @maxopen tinyint,
   @beginmth bMonth, @endmth bMonth, @lastmthapclsd bMonth

select @rcode = 0
   
-- get AP Co#
select @apco = APCo
from dbo.bPRCO (nolock) where PRCo = @prco
if @@rowcount = 0
	begin
	select @msg = 'Invalid PR Company.', @rcode = 1
	goto bspexit
	end
-- get AP GL Co#
select @glco = GLCo
from dbo.bAPCO (nolock) where APCo = @apco
if @@rowcount = 0
	begin
	select @msg = 'Invalid AP Company assigned in PR Co#:' + convert(varchar(3),@prco), @rcode = 1
	goto bspexit
	end
-- get GL Company info
select @lastmthsubclsd = LastMthSubClsd, @maxopen = MaxOpen, @lastmthapclsd = LastMthAPClsd
from dbo.bGLCO (nolock) where GLCo = @glco
if @@rowcount = 0
	begin
	select @msg = 'Invalid GL Company assigned in AP Co#:' + convert(varchar(3),@apco), @rcode = 1
	goto bspexit
	end
   
-- set range of open months
select @beginmth = dateadd(month, 1, @lastmthapclsd) --  #120107 - use last month closed in AP
select @endmth = dateadd(month, @maxopen, @lastmthsubclsd)
   
-- check that expense month is open
if @expmth < @beginmth or @expmth > @endmth
	begin
	select @msg = 'Expense month must be between ' + substring(convert(varchar(8),@beginmth,3),4,5)
       + ' and ' + substring(convert(varchar(8),@endmth,3),4,5), @rcode = 1
   goto bspexit
   end
-- make sure Fiscal Year has been setup for this month
if not exists(select * from bGLFY where GLCo = @glco and BeginMth <= @expmth and FYEMO >= @expmth)
	begin
	select @msg = 'Fiscal Year has not been setup in General Ledger.', @rcode = 1
	goto bspexit
	end
   
-- get earliest paid month from the Pay Period
select @beginmth = BeginMth
from dbo.bPRPC (nolock)
where PRCo = @prco and PRGroup = @prgroup and PREndDate = @prenddate
if @@rowcount = 0
	begin
	select @msg = 'Invalid Pay Period.', @rcode=1
	goto bspexit
	end
-- check that expense month is equal to or later than paid month
if @expmth < @beginmth
	begin
	select @msg =  'Expense month must be equal to or later than ' + substring(convert(varchar(8),@beginmth,3),4,5), @rcode = 1
	goto bspexit
	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRAPUpdateMonthVal] TO [public]
GO
