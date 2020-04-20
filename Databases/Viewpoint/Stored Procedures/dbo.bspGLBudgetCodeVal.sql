SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspGLBudgetCodeVal    Script Date: 8/28/99 9:34:41 AM ******/
   CREATE  proc [dbo].[bspGLBudgetCodeVal]
   /* validates GL Budget Code
    * pass in GL Co# and Budget Code
    * returns Budget Code description
    *	MODIFIED BY:	MV 01/31/03 - #20246 dbl quote cleanup.
   */
   	(@glco bCompany = 0, @bc bBudgetCode = null, @msg varchar(60) output)
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
   
   select @msg = Description from bGLBC
   	where GLCo = @glco and BudgetCode = @bc
   if @@rowcount = 0
   	begin
   	select @msg = 'GL Budget Code not on file!', @rcode = 1
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspGLBudgetCodeVal] TO [public]
GO
