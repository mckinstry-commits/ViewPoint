SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspAPUnappInvMonthVal]
/***********************************************************************************************
* Created: MV 06/27/03
* Modified: GG 02/22/08 - #120107 - separate sub ledger close, validate using AP closed month
*
* Usage: Called from AP Unapproved Invoice form to validate a Month.
*		**  This is also used in SL Worksheet - SL Update to AP Unapproved Invoice  DC #136285
*
* Inputs:
*	@apglco		APGL Co#
*	@mth		Month
*
* Outputs:
*	@msg		Error message if month is closed, warning message id month is not open
*
* Return Code:  0 if successful, 1 if error
*********************************************************************************************/
	@apglco bCompany = null, @mth bMonth = null, @msg varchar(60) output
as

set nocount on
   
declare @lastmthslclsd bMonth, @lastmthglclsd bMonth, @maxopen tinyint,
    @beginmth bMonth, @endmth bMonth, @rcode int, @lastmthapclsd bMonth
   
select @rcode = 0

/* check GL Company - get info */
select @lastmthslclsd = LastMthSubClsd, @maxopen = MaxOpen, @lastmthapclsd = LastMthAPClsd
from dbo.bGLCO (nolock) where GLCo = @apglco
if @@rowcount = 0
	begin
	select @msg = 'Invalid GL Company!', @rcode = 1
	goto bspexit
	end
   
/*set ending month to last mth closed in GL + max # of open mths */
select @endmth = dateadd(month, @maxopen, @lastmthslclsd)
   
-- set beginning month 
select @beginmth = dateadd(month, 1, @lastmthapclsd) -- #120107 - use AP close month
   
if @mth < @beginmth
	begin
	select @msg = 'Unapproved Invoice cannot be added to a closed month', @rcode = 1
	goto bspexit
	end

if @mth > @endmth
	begin
	select @msg = 'Warning: month is beyond open months!'
	end
   
-- make sure Fiscal Year has been setup for this month
if not exists(select 1 from dbo.bGLFY (nolock) where GLCo = @apglco and BeginMth <= @mth and FYEMO >= @mth)
	begin
	select @msg = 'Must first add a Fiscal Year in General Ledger.', @rcode = 1
	goto bspexit
	end
   
bspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPUnappInvMonthVal] TO [public]
GO
