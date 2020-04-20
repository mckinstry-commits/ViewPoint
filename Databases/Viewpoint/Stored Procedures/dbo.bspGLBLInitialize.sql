SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE Proc [dbo].[bspGLBLInitialize]
/***********************************************************
* CREATED BY: SE   ?
* MODIFIED By : JM 6/11/98
*               GG 06/06/00 - Cleanup
*               GG 08/14/00 - Fixed to add missing bGLBL entries
*				GG 08/25/06 - VP6.0 cleanup
*				GG 10/17/08 - #130647 - correct bGLYB insert
*
* USAGE:
* 	Adds Fiscal Year Balance entries (bGLYB) and Monthly Balances (bGLBL)
*  for a range of GL Accounts within a fiscal year.
*
* INPUT PARAMETERS
*	@glco         GL Company #
*   @begglacct    Starting GL Account
*   @endglacct    Ending GL Account
*	@fyemo        Fiscal Year Ending Month
*
* RETURN VALUE
*   	0 - success
*   	1 - failure
*****************************************************/

   @glco bCompany, @begglacct bGLAcct, @endglacct bGLAcct, @fyemo bMonth
   
as
set nocount on

declare @begmth bMonth

-- add Fiscal Year Balance entries for GL Accounts within range, skips existing entries
insert bGLYB (GLCo, FYEMO, GLAcct, BeginBal, NetAdj, Notes)
select @glco, @fyemo, a.GLAcct, 0, 0, null
from bGLAC a (nolock)
--left join bGLYB y  (nolock) on y.GLCo = a.GLCo and y.GLAcct = a.GLAcct --#130467 removed this join
where a.GLCo = @glco and a.GLAcct >= @begglacct and a.GLAcct <= @endglacct
   and	a.GLAcct not in (select GLAcct from bGLYB (nolock) where GLCo = @glco and FYEMO = @fyemo)

-- get Fiscal Year beginning month
select @begmth = BeginMth
from bGLFY (nolock) where GLCo = @glco and FYEMO = @fyemo

-- add Balance entries for GL Accounts within range - one for each month within fiscal year, skip existing entries
while @begmth <= @fyemo
	begin
	insert bGLBL (GLCo, GLAcct, Mth, NetActivity, Debits, Credits)
	select a.GLCo, a.GLAcct, @begmth, 0, 0, 0
	from bGLAC a (nolock)
	where a.GLCo = @glco and (a.GLAcct >= @begglacct and a.GLAcct <= @endglacct)
       and a.AcctType <> 'H'   -- skip Heading Accounts
       and a.GLAcct not in (select GLAcct from bGLBL (nolock) where GLCo = @glco and Mth = @begmth)

	select @begmth = dateadd(mm,1,@begmth)	-- next month
end

GO
GRANT EXECUTE ON  [dbo].[bspGLBLInitialize] TO [public]
GO
