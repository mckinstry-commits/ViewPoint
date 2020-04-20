SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE       procedure [dbo].[bspGLBudgetAdjustAnnually]
   /************************************************************************
   * CREATED: 	MH 	11/26/2003    
   * MODIFIED: GWC 11/19/2004 #26243: Added BudgetCode restriction to the Where
   *								   clauses for the DELETE and Total calculations
   *								   from GLBD 
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
   	@fyemth bMonth, @amt bDollar, @drcr char(1), @total bDollar output, 
   	 @normbalout varchar(2) output, @msg varchar(80) = '' output)
   
   as
   set nocount on
   
       declare @rcode int, @budgetamt bDollar, @i as tinyint, @subtotal bDollar,
   	@begmth bMonth, @loopcntrl smallint
   
       select @rcode = 0
   
   
   
   	select @begmth = BeginMth from dbo.GLFY where GLCo = @glco and FYEMO = @fyemth
   	select @loopcntrl = datediff(mm, @begmth, @fyemth)
   
   	select @budgetamt = @amt / (@loopcntrl + 1)
   
   	--GWC #26243
   	delete dbo.GLBD where GLCo = @glco and GLAcct = @glacct and 
   	(Mth >= @begmth and Mth <= @fyemth) AND BudgetCode = @budgetcode
   	
   select @i = 0, @subtotal = 0
   
   while @i <= @loopcntrl
   begin
   
   	if @i = @loopcntrl 
   		select @budgetamt = abs(@amt) - abs(@subtotal)
   
   	--make sure the sign is correct
   	if @drcr = 'C' and @budgetamt > 0
   		select @budgetamt = @budgetamt * -1
   
   	if @drcr = 'D'
   		select @budgetamt = abs(@budgetamt)
   
   	insert dbo.GLBD (GLCo, GLAcct, BudgetCode, Mth, BudgetAmt)
   	values (@glco, @glacct, @budgetcode, dateadd(mm, @i, @begmth),
   	@budgetamt)
   
   	select @subtotal = @subtotal + @budgetamt
   
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
GRANT EXECUTE ON  [dbo].[bspGLBudgetAdjustAnnually] TO [public]
GO
