SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     procedure [dbo].[bspGLBudgetAdjustMonthly]
   /************************************************************************
   * CREATED:   MH 11/26/03    
   * MODIFIED: GWC 11/19/2004 #26243: Added BudgetCode restriction to the Where
   *								   clauses for the DELETE and Total calculations
   *								   from GLBD *
   * Purpose of Stored Procedure
   *
   *    Create monthly entries in GLBD for a GLFY provided.  Used by GL Budgets
   *    
   *           
   * Notes about Stored Procedure
   * 
   *
   * returns 0 if successfull 
   * returns 1 and error msg if failed
   *
   *************************************************************************/
   
       (@glco bCompany = null, @glacct bGLAcct = null, @budgetcode bBudgetCode,
   	@fyemth bMonth, @amt bDollar, @drcr char(1), @total bDollar output, 
   	 @normbalout varchar(2) output, @msg varchar(80) = '' output)
   
   as
   set nocount on
   
       declare @rcode int, @i smallint, @begmth bMonth, @loopcntrl smallint
   
       select @rcode = 0, @i = 0, @loopcntrl = 0
   
   	if @glco is null
   	begin
   		select @msg = 'Missing GL Company.', @rcode = 1
   		goto bspexit
   	end
   
   	if @glacct is null
   	begin
   		select @msg = 'Missing GL Account.', @rcode = 1
   		goto bspexit
   	end
   
   	if @budgetcode is null
   	begin
   		select @msg = 'Missing Budget Code.', @rcode = 1
   		goto bspexit
   	end
   
   	if @fyemth is null
   	begin
   		select @msg = 'Missing GL Fiscal Year Ending Month/Year.', @rcode = 1
   		goto bspexit
   	end
   
   	if @amt is null
   	begin
   		select @msg = 'Missing Budget amount.', @rcode = 1	
   		goto bspexit
   	end
   
   	if @drcr is null
   	begin
   		select @msg = 'Missing Normal Balance.', @rcode = 1
   		goto bspexit
   	end
   
   	select @begmth = BeginMth from dbo.GLFY where GLCo = @glco and FYEMO = @fyemth
   
   	select @loopcntrl = datediff(mm, @begmth, @fyemth)
   	--select @startmth = dateadd(mm, -11, @fyemth)
   
   	--GWC #26243
   	delete dbo.GLBD where GLCo = @glco and GLAcct = @glacct and 
   	(Mth >= @begmth and Mth <= @fyemth) AND BudgetCode = @budgetcode
   
   	if @drcr = 'C' and @amt > 0
   		select @amt = @amt * -1
   
   	if @drcr = 'D'
   		select @amt = abs(@amt)
   
   	while @i <= @loopcntrl
   	begin
   /*
   		insert GLBD (GLCo, GLAcct, BudgetCode, Mth, BudgetAmt)
   		values (@glco, @glacct, @budgetcode, dateadd(mm, (@i * -1), @fyemth),
   		@amt)
   */
   		insert dbo.GLBD (GLCo, GLAcct, BudgetCode, Mth, BudgetAmt)
   		values (@glco, @glacct, @budgetcode, dateadd(mm, @i, @begmth),
   		@amt)
   		select @i = @i + 1
   	end
   
   	--GWC #26243
   	select @total = sum(BudgetAmt) from dbo.GLBD where GLCo = @glco and GLAcct = @glacct and 
   	(Mth >= @begmth and Mth <= @fyemth) AND BudgetCode = @budgetcode
   
   	if @total < 0
   		select @normbalout = 'Cr'
   	else if @total > 0
   		select @normbalout = 'Dr'
   	else if @total = 0
   		select @normbalout = null
   
   	select @total = abs(@total)
   
   
   bspexit:
   
        return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspGLBudgetAdjustMonthly] TO [public]
GO
