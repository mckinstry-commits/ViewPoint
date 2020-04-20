SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE        procedure [dbo].[bspGLBudgetAdjustQuarterly]
   /************************************************************************
   * CREATED:    
   * MODIFIED: GWC 11/19/2004 #26243: Added BudgetCode restriction to the Where
   *								   clauses for the DELETE and Total calculations
   *								   from GLBD 
   *			DANF 06/12/2005 # 26060 : Corrected Quarterly Budget by sending crdr for each qtr amount.
   *
   * Purpose of Stored Procedure
   *
   *    
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
   	@fyemth bMonth, @q1amt bDollar, @q2amt bDollar, @q3amt bDollar, @q4amt bDollar, 
   	@drcr1 char(1), @drcr2 char(1), @drcr3 char(1), @drcr4 char(1), @total bDollar output, @normbalout varchar(2) output, 
   	@msg varchar(80) = '' output)
   
   as
   set nocount on
   
   	declare @budgetamt bDollar, @mthindex int, @mthamt bDollar, @subtotal bDollar,
   	@rcode int, @i smallint, @begmth bMonth, @loopcntrl smallint, @drcr char(1)
   
       select @rcode = 0, @i = 0
   
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
   
   	if @drcr1 is null or @drcr2 is null or @drcr3 is null or @drcr4 is null
   	begin
   		select @msg = 'Missing Normal Balance.', @rcode = 1
   		goto bspexit
   	end
   
   	select @begmth = BeginMth from dbo.GLFY with (nolock) where GLCo = @glco and FYEMO = @fyemth
   	select @loopcntrl = (datediff(mm, @begmth, @fyemth) + 1)
   
   	--select @startmth = dateadd(mm, -11, @fyemth)
   
   	--GWC #26423
   	delete dbo.GLBD where GLCo = @glco and GLAcct = @glacct and 
   	(Mth >= @begmth and Mth <= @fyemth) AND BudgetCode = @budgetcode
   
   select @mthindex = 1, @subtotal = 0
   
   while @mthindex <= @loopcntrl 
   begin
   
   	if @mthindex <= 3 --1st qtr
   		select @budgetamt = isnull(@q1amt, 0), @drcr = @drcr1
   	else
   		if @mthindex <= 6 --2nd qtr
   			select @budgetamt = isnull(@q2amt, 0), @drcr = @drcr2
   		else
   			if @mthindex <= 9 --3rd qtr
   				select @budgetamt = isnull(@q3amt, 0), @drcr = @drcr3
   			else
   				if @mthindex <= 12 --4th qtr
   					select @budgetamt = isnull(@q4amt, 0), @drcr = @drcr4
   
   --if remander is zero we are on the 3rd, 6th, 9th, or 12th month
   	if @mthindex % 3 <> 0
   	begin
   		select @mthamt = @budgetamt / 3
   		select @subtotal = @subtotal + @mthamt		
   	end
   	else
   	begin
   		select @mthamt = (@budgetamt - @subtotal)
   		select @subtotal = 0
   	end
   
   --make sure the sign is correct
   	if @drcr = 'C' and @mthamt > 0
   		select @mthamt = @mthamt * -1
   
   	if @drcr = 'D'
   		select @mthamt = abs(@mthamt)
   
   		insert dbo.GLBD (GLCo, GLAcct, BudgetCode, Mth, BudgetAmt)
   		values (@glco, @glacct, @budgetcode, dateadd(mm, @mthindex - 1, @begmth),
   		@mthamt)
   
   	select @mthindex = @mthindex + 1
   
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
GRANT EXECUTE ON  [dbo].[bspGLBudgetAdjustQuarterly] TO [public]
GO
