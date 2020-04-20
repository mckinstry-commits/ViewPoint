SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[bspGLGetBudgetTotal]
   /************************************************************************
   * CREATED:    
   * MODIFIED: GWC 11/19/2004 #26243: Added BudgetCode restriction to the Where
   *								   clause for the Total calculation from GLBD 
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
   	@fyemth bMonth, @total bDollar output, @normbalout varchar(2) output, 
   	@msg varchar(80) = '' output)
   
   as
   set nocount on
   
       declare @rcode int, @begmth bMonth
   
       select @rcode = 0
   
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
   
   	select @begmth = BeginMth from dbo.GLFY where GLCo = @glco and FYEMO = @fyemth
   
   	--GWC #26243
   	select @total = sum(BudgetAmt) from GLBD where GLCo = @glco and GLAcct = @glacct and 
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
GRANT EXECUTE ON  [dbo].[bspGLGetBudgetTotal] TO [public]
GO
