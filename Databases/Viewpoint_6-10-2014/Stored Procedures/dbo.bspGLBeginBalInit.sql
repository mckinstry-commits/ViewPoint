SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE   procedure [dbo].[bspGLBeginBalInit]
/*******************************************************************
*  CREATED: ???
*  MODIFIED:  GG 07/12/99  Fixed Retained Earnings update
*				GG 02/17/06 - cleanup
*
*  USAGE:
*  Used to initialize GL Beginning Balances.  Sets each accounts Begin Balance
*  in bGLYB based on Account Type:
*      Income, Expense, Memo, Heading = 0.00
*      Profit/Loss = Prior year ending balance + (sum of prior year ending balance for all Income and Expense accounts)
*      All others = Prior year ending balance
*
*  INPUT:
*      @glco       GL Company #
*      @fyemo      Fiscal Year Ending Month
*
*  OUTPUT:
*      @errmsg     Error message
*
*  RETURN:
*      0           Success
*      1           Failure
********************************************************************/
   
	(@glco bCompany = 0, @fyemo bMonth = null, @errmsg varchar(255) output)
   
as
set nocount on

declare @rcode int, @opencursor tinyint, @placct bGLAcct, @glcoca char(1),
@priorfyemo bMonth, @glacct bGLAcct, @accttype char(1), @active bYN, @cashaccrual char(1),
@bbal bDollar, @ebal bDollar, @priorbegbal bDollar, @prioradj bDollar, @prioractivity bDollar,
@priorbeginmth bMonth, @plamt bDollar

select @rcode = 0, @opencursor = 0, @placct = null, @plamt = 0

/* validate GL company */
select @glcoca = CashAccrual
from dbo.bGLCO (nolock)
where GLCo = @glco
if @@rowcount = 0
	begin
	select @errmsg = 'Invalid GL Company!', @rcode = 1
	goto bspexit
	end
   
/* validate Fiscal Year */
exec @rcode = bspGLFYEMOVal @glco, @fyemo, @errmsg output
if @rcode <> 0 goto bspexit
   
/* get prior Fiscal Year */
select @priorfyemo = max(FYEMO)
from dbo.bGLFY (nolock)
where GLCo = @glco and FYEMO < @fyemo
if @priorfyemo is null
	begin
   	select @errmsg = 'No prior Fiscal Year exists!', @rcode = 1
   	goto bspexit
   	end
   
-- get Prior Year Beginning Month
select @priorbeginmth = BeginMth
from dbo.bGLFY (nolock)
where GLCo = @glco and FYEMO = @priorfyemo
   
/* declare cursor on GL Account */
declare bcGLYB_begbal cursor fast_forward for
select GLAcct, AcctType, Active, CashAccrual
from dbo.bGLAC (nolock)
where GLCo = @glco
   
/* open cursor */
open bcGLYB_begbal

/* set open cursor flag to true */
select @opencursor = 1
   
/* loop through all rows in cursor */
process_loop:
	fetch next from bcGLYB_begbal into @glacct, @accttype, @active, @cashaccrual

	if (@@fetch_status <> 0) goto process_loop_end

   	select @bbal = 0, @ebal = 0    -- initialize balances

   	if @accttype = 'P' and @placct is null select @placct = @glacct     /* assign Profit/Loss account */

	if @accttype = 'H' or @accttype = 'M' goto begbal_update    /* skip if Heading or Memo accounts */

   	-- get prior year ending balance and net adjustments
   	select @priorbegbal = 0, @prioradj = 0
   
 	select @priorbegbal = BeginBal, @prioradj = NetAdj
    from dbo.bGLYB (nolock)
    where GLCo = @glco and GLAcct = @glacct and FYEMO = @priorfyemo
   
    -- get prior year net activity
    select @prioractivity = isnull(sum(NetActivity),0)
    from dbo.bGLBL (nolock)
    where GLCo = @glco and GLAcct = @glacct and Mth >= @priorbeginmth and Mth <= @priorfyemo
   
    -- calculate prior year ending balance
    select @ebal = @priorbegbal + @prioradj + @prioractivity
   
    select @bbal = @ebal    -- initialize new beginning balance
   
    if @glcoca = 'C' and @cashaccrual = 'C' goto begbal_update  -- cash basis
   
    -- accumulate Retained Earnings from Expense and Income Accounts
    if @accttype in ('E','I')
    	begin
        select @plamt = @plamt + @ebal
        select @bbal = 0    -- reset beginning balance
        end
   
    begbal_update:
        update dbo.bGLYB
        set BeginBal = @bbal    -- replace beginning balance
        where GLCo = @glco and FYEMO = @fyemo and GLAcct = @glacct
        if @@rowcount = 0 and (@active = 'Y' or @bbal <> 0)
        	begin
            insert dbo.bGLYB (GLCo, FYEMO, GLAcct, BeginBal, NetAdj)
            values (@glco, @fyemo, @glacct, @bbal, 0)
            end
   
		goto process_loop
   
process_loop_end:   /* profit/loss update */
	if @placct is null
     	begin
        select @errmsg = 'Missing Profit/Loss GL Account!', @rcode = 1
        goto bspexit
        end
   
	update dbo.bGLYB
    set BeginBal = BeginBal + @plamt    -- retained earnings beginning balance + profit/loss amount
    where GLCo = @glco and FYEMO = @fyemo and GLAcct = @placct
    if @@rowcount = 0
    	begin
        insert dbo.bGLYB (GLCo, FYEMO, GLAcct, BeginBal, NetAdj)
        values (@glco, @fyemo, @placct, @plamt, 0)
        end
   
    select @errmsg = 'Beginning balances successfully initialized for ' + substring(convert(varchar,@fyemo,1),1,3) + substring(convert(varchar,@fyemo,1),7,2)
   
   
bspexit:
	if @opencursor = 1
    	begin
    	close bcGLYB_begbal
    	deallocate bcGLYB_begbal
    	end
   
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspGLBeginBalInit] TO [public]
GO
