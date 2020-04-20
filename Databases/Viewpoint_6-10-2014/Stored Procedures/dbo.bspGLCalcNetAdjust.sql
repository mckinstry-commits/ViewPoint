SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspGLCalcNetAdjust    Script Date: 8/28/99 9:32:46 AM ******/
   CREATE  procedure [dbo].[bspGLCalcNetAdjust]
   /********************************************************
    * CREATED BY: MH  6/9/99
    * MODIFIED By:  MH 10/29/99 - Corrected to calculate and return end balance
    *               MH 3/8/00 - Hardcoded GLCo in error.  See 3/8/00 change below.
    *				 MV 01/31/03 - #20246 dbl quote cleanup.
    *
    * USAGE: Used by GLPriorActivity to calculate net adjustments.
    *
    * Pass: GLCo, GLAccount, StartDate, EndDate (corresponding to start and end of a fiscal year)
    *
    * Returns: 0 and message if successful, 1 and message if error
    *********************************************************/
   
   /*Parameter list */
   (@glco bCompany = null, @glacct bGLAcct, @startdate bDate = null, @enddate bDate = null,  
    @endbal bDollar output, @msg varchar(150) output)
   
   --@netadjust bDollar output
   
   as
   set nocount on
   
   /*Locals */
   declare @rcode int, @totaldebit bDollar, @totalcredit bDollar, @netadjust bDollar, @begbal bDollar
   
   select @rcode = 0
   
   /*check for missing parameters */
   
   if @glco is null
        begin
        select @msg = 'Missing GL Company!', @rcode = 1
        goto bspexit
        end
   
   if @glacct is null
        begin
        select @msg = 'Missing GL Account!', @rcode = 1
        goto bspexit
        end     
   
   if @startdate is null
        begin
        select @msg = 'Missing starting fiscal year month!', @rcode = 1
        goto bspexit
        end     
   
   if @enddate is null
        begin
        select @msg = 'Missing ending fiscal year month!', @rcode = 1
        goto bspexit
        end 
   
   
   select @totaldebit = (select sum(Debits) from GLBL where GLCo = @glco and GLAcct = @glacct and 
                            Mth >= @startdate and Mth <= @enddate)
   
   if @totaldebit is null
        select @totaldebit = 0.00
   
   select @totalcredit = (select sum(Credits) from GLBL where GLCo = @glco and GLAcct = @glacct and 
                            Mth >= @startdate and Mth <= @enddate)
   
   if @totalcredit is null
        select @totalcredit = 0.00
   
   --accidently hard coded GLCo = 1.  Should have been GLCo = @glco.  Corrected.  mh 3/8/00
   select @netadjust = NetAdj from GLYB where GLCo = @glco and FYEMO = @enddate and GLAcct = @glacct
   
   if @netadjust is null
       select @netadjust = 0.00
   
   select @begbal = BeginBal from GLYB where GLCo = @glco and FYEMO = @enddate and GLAcct = @glacct
   
   if @begbal is null
       select @begbal = 0.00
   
   select @endbal =  @begbal + @netadjust + (@totaldebit - @totalcredit)
   
   bspexit:
   return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspGLCalcNetAdjust] TO [public]
GO
