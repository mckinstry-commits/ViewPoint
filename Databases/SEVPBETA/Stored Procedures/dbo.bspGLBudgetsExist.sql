SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspGLBudgetsExist    Script Date: 8/28/99 9:34:42 AM ******/
   CREATE  proc [dbo].[bspGLBudgetsExist]
   /*
    * Created By SAE  8/28/97
    * MODIFIED BY		MV 01/31/03 - #20246 dbl quote cleanup. 
    *
    * validates GL Budget Code for Budget initialize From Budget.
    * pass in GL Co# FYEMO and Budget Code and this will 
    * Validate Budget code and make sure that Budgets exist for that FYEMO
    * returns Budget Code description
   */
   	(@glco bCompany = 0, @fyemo bMonth, @bc bBudgetCode = null, @msg varchar(60) output)
   as
   set nocount on
   declare @rcode int
   select @rcode = 0
   
   if @glco=0
   	begin
   	select @msg = 'Missing GL Company!', @rcode = 1
   	goto bspexit
   	end
   
   if @bc is null
   	begin
   	select @msg = 'Missing GL Budget Code!', @rcode = 1
   	goto bspexit
   	end
   
   select @msg = Description from GLBC
   	where GLCo = @glco and BudgetCode = @bc
   if @@rowcount = 0
   	begin
   	select @msg = 'GL Budget Code not on file!', @rcode = 1
   	goto bspexit
   	end
   
   if not exists (select * from bGLBR where GLCo=@glco and FYEMO=@fyemo and BudgetCode=@bc)
   	begin
   	select @msg = 'There are no budgets in this fiscal year to initialize from!', @rcode = 1
   	goto bspexit
   	end
   
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspGLBudgetsExist] TO [public]
GO
