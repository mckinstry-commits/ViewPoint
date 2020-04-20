SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspGLBudgetCompare]
/**************************************************
* Created: GG 09/11/06
* Modified: 
*
* Usage:
*   Called by GL Budgets form to list monthly actual or budget 
*   values for comparison.
*
* Inputs:
*   @glco			GL company
*   @fyemo			Fiscal Year ending month
*	@glacct			GL Account
*	@option			'A'=actual, 'B'=budget
*   @budgetcode		Budget code  
*
* Outputs:
*	@total			Fiscal year total 
*	@drcr			Debit or Credit   
*
* Return:
*	resultset of monthly actual or budget values
**************************************************/
	(@glco bCompany = null, @fyemo bMonth = null, @glacct bGLAcct = null,
	 @option char(1) = '', @budgetcode bBudgetCode = null,
	 @total bDollar = 0 output, @drcr char(2) = 'Dr' output)
as
set nocount on
if @option = 'A'   -- actual monthly balances
	begin
	select Mth, abs(NetActivity) as [Amount], case when NetActivity < 0 then 'Cr' else 'Dr' end as [Dr/Cr]
	from dbo.GLBLWithFYEMO (nolock)
	where GLCo = @glco and FYEMO = @fyemo and GLAcct = @glacct 
	order by GLCo, Mth
	-- get total
	select @total = abs(sum(NetActivity)), @drcr = case when sum(NetActivity) < 0 then 'Cr' else 'Dr' end 
	from dbo.GLBLWithFYEMO (nolock)
	where GLCo = @glco and FYEMO = @fyemo and GLAcct = @glacct 
	end
if @option = 'B'	-- monthly budgets
	begin
	select Mth, abs(BudgetAmt) as [Amount], case when BudgetAmt < 0 then 'Cr' else 'Dr' end as [Dr/Cr]
	from dbo.GLBDWithFYEMO (nolock)
	where GLCo = @glco and FYEMO = @fyemo and GLAcct = @glacct and BudgetCode = @budgetcode
	order by GLCo, Mth
	-- get total
	select @total = abs(sum(BudgetAmt)), @drcr = case when sum(BudgetAmt) < 0 then 'Cr' else 'Dr' end 
	from dbo.GLBDWithFYEMO (nolock)
	where GLCo = @glco and FYEMO = @fyemo and GLAcct = @glacct and BudgetCode = @budgetcode
	end

return

GO
GRANT EXECUTE ON  [dbo].[vspGLBudgetCompare] TO [public]
GO
