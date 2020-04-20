SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJBHQBatchMonthVal    Script Date: 11/20/02 9:34:48 AM ******/
CREATE  procedure [dbo].[bspJBHQBatchMonthVal]
/***********************************************************************************************
*Created: TJL  11/20/02 - Issue #17278
*Last Revised:  TJL  04/28/06 - Issue #121027, Catch illegal open BillMonths exceeding GL Year limits
*			GG 02/25/08 - #120107 - separate sub ledger close - use AR close month
*
*
* Usage: Called from Batch Selection form to validate a Batch Month.
*
* Input Params:  JC GLCo#, JC ARCo#, BillMonth, InputMonth, and Source
*
* Output Params: Error message if invalid
*
* Return Code:  0 if successfull, 1 if error
*********************************************************************************************/
@JCglco bCompany = null, @JCarco bCompany, @billmth bMonth = null, @inputmth bMonth = null, 
@source bSource = null, @msg varchar(100) output
as

set nocount on
   
declare @JClastmthsubclsd bMonth, @JClastmthglclsd bMonth, @JCmaxopen tinyint, @JCbeginmth bMonth,
	@JCendmth bMonth, @ARlastmthsubclsd bMonth, @ARlastmthglclsd bMonth, @ARmaxopen tinyint, 
	@ARbeginmth bMonth,	@ARendmth bMonth, @JCARglco bCompany, @rcode int, @ARlastmtharclsd bMonth

select @rcode = 0

/* get AR.GLCo for this JC Company */
select @JCARglco = GLCo
from bARCO with (nolock)
where ARCo = @JCarco

/* check GL Company - get info */
select @JClastmthsubclsd = LastMthSubClsd, @JClastmthglclsd = LastMthGLClsd,
	@JCmaxopen = MaxOpen
from bGLCO with (nolock)
where GLCo = @JCglco
if @@rowcount = 0
	begin
	select @msg = 'Invalid JC GL Company!', @rcode = 1
	goto bspexit
	end
   
select @ARlastmthsubclsd = LastMthSubClsd, @ARlastmthglclsd = LastMthGLClsd,	-- #120107 - use AR close month
	@ARmaxopen = MaxOpen, @ARlastmtharclsd = LastMthARClsd
from bGLCO with (nolock)
where GLCo = @JCARglco
if @@rowcount = 0
	begin
	select @msg = 'Invalid AR GL Company!', @rcode = 1
	goto bspexit
	end

/* set ending month to last mth closed in subledgers + max # of open mths */
select @JCendmth = dateadd(month, @JCmaxopen, @JClastmthsubclsd)
select @ARendmth = dateadd(month, @ARmaxopen, @ARlastmthsubclsd)

/* set beginning month based on source */
select @JCbeginmth = dateadd(month, 1, @JClastmthsubclsd) -- subledger
if substring(@source,1,2) = 'GL' select @JCbeginmth = dateadd(month, 1, @JClastmthglclsd) -- general ledger

select @ARbeginmth = dateadd(month, 1, @ARlastmtharclsd) -- AR close month
if substring(@source,1,2) = 'GL' select @ARbeginmth = dateadd(month, 1, @ARlastmthglclsd) -- general ledger

/* begin evaluation process. Conditions are:
  1) Bills being processed are all for a closed month but the default input has been
  accepted by the user (ie. batch month same as closed bill month).  User must be
  forced to use a valid batch in a different and Open month in AR and JC.
  2) Bills being processed are all for a closed month.  (User has select a batch month
  different from the bill month, which is correct but the batch month must also 
  fall within a valid open month range for both JC and AR. At this point the closed month
  may be either in JC or even AR.  (Probably these are bills being changed though it is 
	  possible that the JC month is open and it is the AR month which is closed.  In this
  case, Job Billing would allow this bill to be marked for 'D'elete which will be 
  rejected later by batch Validation.  We do not want to let an 'A' type transaction
	  or a 'D' type transaction get posted in a different month) 
  3) Bills being processed are all in open months for both JC and AR and default input
  has been accepted by user (ie. batch month same as open bill month).  This is a
  legal combination.  Allow user to proceed immediately.
  4) Bills being process are all in open months for both JC and AR but user has input
  a batch month different from the bill months.  This is illegal.  Open month bills
  must always be processed using a batchmth that is same as the billmonth.
*/
--1
if @billmth = @inputmth and (@billmth <= @JClastmthsubclsd or @billmth <= @ARlastmtharclsd)
	begin	/* Begin closed month, input batch same as closed mth errors */
	/* Default Entry when user interfaces Changed Bills from a closed month.
	   No need to test for EndMonth. */
	if @billmth <= @JClastmthsubclsd
		begin
		/* If JC closed, give JC open batch month range */
		select @msg = 'You are changing Bills from a closed month in JC.  Month must be between '
		select @msg = @msg + isnull(substring(convert(varchar(8),@JCbeginmth,1),1,3),'') + isnull(substring(convert(varchar(8), @JCbeginmth, 1),7,2),'')
		select @msg = @msg + ' and '
		select @msg = @msg + isnull(substring(convert(varchar(8),@JCendmth,1),1,3),'') + isnull(substring(convert(varchar(8), @JCendmth, 1),7,2),''), @rcode = 1
		goto bspexit
		end

	if @billmth <= @ARlastmtharclsd
		begin
		/* If AR closed, give AR open batch month range */
		select @msg = 'You are changing Bills from a closed month in AR.  Month must be between '
		select @msg = @msg + isnull(substring(convert(varchar(8),@ARbeginmth,1),1,3),'') + isnull(substring(convert(varchar(8), @ARbeginmth, 1),7,2),'')
		select @msg = @msg + ' and '
		select @msg = @msg + isnull(substring(convert(varchar(8),@ARendmth,1),1,3),'') + isnull(substring(convert(varchar(8), @ARendmth, 1),7,2),''), @rcode = 1
		goto bspexit
		end
	end		/* End closed month, input batch same as closed mth errors */
--2
else if @billmth <> @inputmth and (@billmth <= @JClastmthsubclsd or @billmth <= @ARlastmtharclsd)
   	begin	/* Begin closed month, different batch checks */
   	/* User inputs a different batch month to interface changed Bills in a closed month.
   	   Determine which module is closed, AR or JC, and do further checks. */
   	if @billmth <= @JClastmthsubclsd
   		begin
   		/* If JC closed and input is bad give error, else move on to AR checks. */
   		if @inputmth <= @JClastmthsubclsd or @inputmth > @JCendmth
   			begin
   			/* User may not use a closed month to process these changes. */
   			select @msg = 'You are changing Bills from a closed month in JC.  Month must be between '
   			select @msg = @msg + isnull(substring(convert(varchar(8),@JCbeginmth,1),1,3),'') + isnull(substring(convert(varchar(8), @JCbeginmth, 1),7,2),'')
   			select @msg = @msg + ' and '
   			select @msg = @msg + isnull(substring(convert(varchar(8),@JCendmth,1),1,3),'') + isnull(substring(convert(varchar(8), @JCendmth, 1),7,2),''), @rcode = 1
   			goto bspexit
   			end
   		end
   
   	if @billmth <= @ARlastmtharclsd
   		begin
   		/* One or more Modules are closed.  JC comparison did not fail so check AR */
   		if @inputmth <= @ARlastmtharclsd or @inputmth > @ARendmth
   			begin
   			/* User may not use a closed month to process these changes. */
   			select @msg = 'You are changing Bills from a closed month in AR.  Month must be between '
   			select @msg = @msg + isnull(substring(convert(varchar(8),@ARbeginmth,1),1,3),'') + isnull(substring(convert(varchar(8), @ARbeginmth, 1),7,2),'')
   			select @msg = @msg + ' and '
   			select @msg = @msg + isnull(substring(convert(varchar(8),@ARendmth,1),1,3),'') + isnull(substring(convert(varchar(8), @ARendmth, 1),7,2),''), @rcode = 1
   			goto bspexit
   			end
   		end
   
	/* We are processing a closed month bill change but user has selected an appropriate open
	   month batch in both JC and AR.  It appears to be the correct selection however it is
	   possible to have arrived here and be processing a bill in JB whose JC month is not
	   closed but whos AR Month is.  In this case, JB would have allowed the bill to be
	   marked for 'D'elete or 'A'ctive.  Since this is a batch selection form check involving
	   possibly multiple bills (some marked 'C', others marked 'D' or 'A'), we must let
	   the user proceed and validation will catch a bill marked 'D' or 'A' and not being 
	   posted to the same month. */
   	goto bspexit
   	end		/* End closed month, different batch checks */
--3
else if @billmth = @inputmth and @billmth > @JClastmthsubclsd and @billmth > @ARlastmtharclsd
   	begin
   	/* Default entry when user interfaces any Bill in an open month. */
	if @inputmth > @JCendmth
		begin
		/* User must process Open Month Bills within a legal Batch Month. */
		select @msg = 'Invalid JC GLSubLedger Month. Must be between '
		select @msg = @msg + isnull(substring(convert(varchar(8),@JCbeginmth,1),1,3),'') + isnull(substring(convert(varchar(8), @JCbeginmth, 1),7,2),'')
		select @msg = @msg + ' and '
		select @msg = @msg + isnull(substring(convert(varchar(8),@JCendmth,1),1,3),'') + isnull(substring(convert(varchar(8), @JCendmth, 1),7,2),''), @rcode = 1
		goto bspexit
		end

	if @inputmth > @ARendmth
		begin
		/* User must process Open Month Bills within a legal Batch Month. */
		select @msg = 'Invalid AR GLSubLedger Month. Must be between '
		select @msg = @msg + isnull(substring(convert(varchar(8),@ARbeginmth,1),1,3),'') + isnull(substring(convert(varchar(8), @ARbeginmth, 1),7,2),'')
		select @msg = @msg + ' and '
		select @msg = @msg + isnull(substring(convert(varchar(8),@ARendmth,1),1,3),'') + isnull(substring(convert(varchar(8), @ARendmth, 1),7,2),''), @rcode = 1
		goto bspexit
		end
	end
--4
else if @billmth <> @inputmth and @billmth > @JClastmthsubclsd and @billmth > @ARlastmtharclsd
   	begin
   	/* User inputs different batch month to interface Bills from an open month */
   	select @msg = 'Batch Month must be the same as Bill Month. ', @rcode = 1
   	goto bspexit
   	end
   
/* All previous checks are OK.  Make sure JC Fiscal Year has been setup for this month 
   This check not required for Closed Month Bills.*/
if not exists(select 1 from bGLFY where GLCo = @JCglco and BeginMth <= @inputmth and FYEMO >= @inputmth)
	begin
	select @msg = 'Must first add a Fiscal Year in General Ledger for JC GLCo.', @rcode = 1
	goto bspexit
	end
   
/* All previous checks are OK.  Make sure AR Fiscal Year has been setup for this month 
   This check not required for Closed Month Bills.*/
if not exists(select 1 from bGLFY where GLCo = @JCARglco and BeginMth <= @inputmth and FYEMO >= @inputmth)
	begin
	select @msg = 'Must first add a Fiscal Year in General Ledger for AR GLCo.', @rcode = 1
	goto bspexit
	end

bspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBHQBatchMonthVal] TO [public]
GO
