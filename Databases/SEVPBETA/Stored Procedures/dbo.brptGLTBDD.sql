SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.brptGLFinDet    Script Date: 8/28/99 9:33:49 AM ******/
     /****** Object:  PROC dbo.brptGLFinDet    Script Date: 3/3/97 2:24:47 PM ******/
     --drop PROC brptGLTBDD
    CREATE                   PROC [dbo].[brptGLTBDD]
     (@GLCo bCompany, @BegAcct bGLAcct=' ', @EndAcct bGLAcct='zzzzzzzzzz',
     @BegMonth bMonth ='01/01/1950', @EndMonth bMonth = '12/01/2050', @IncludeInactive char(1)='N',
     @Source varchar(20)=' ',@Journal varchar(20)=' ', @DetailLevel char(1) = 'D')
     /*created 8/26/97 */
     /*changed report to use GLAC instead of GLAC for security*/
     /* Mod 4/2/03 E.T. fixed to make ansii standard for Crystal 9.0 
                        fixed : using tables instead of views. Issue #20721 */
     /* Mod 4/29/03 JRE changed #GLDetail.GLCo from NOT Null to Null Issue 21042 
        Mod 6/12/03 DH Removed UNIQUE from clustered index on GLDetail - caused error in Crystal 9
        Issue 20721*
        Mod 8/5/03 DH Issue 22016.  Remmed out update section that added net activity a second time to the
                                    Beginning Balance. */
    /*  Issue 25905 Added with(nolock) to the from and join statements NF 11/11/04 */
    /*  Issue 29150 Change to two SP like the other GL Reports NF 08/11/05 */
     
     as
     set nocount on
     declare @FYEMO bMonth, @FYBMO bMonth, @EndAcctFull bGLAcct,@ErrorMessage varchar(60)
     select @EndAcctFull=RTrim(@EndAcct)+'zzzzzzzzzz'
       
     /* if no begin month then get it from the end month */
     if @BegMonth is null
     begin
     select @BegMonth = GLFY.BeginMth
     from GLFY with(nolock) 
     where GLFY.GLCo=@GLCo and @EndMonth>=GLFY.BeginMth and @EndMonth<=GLFY.FYEMO
     if @@rowcount=0
     	begin
     	select @ErrorMessage= '**** Fiscal Year End not set up in GLFY ****'
     	end
   	goto selectresults
     end  
   
    
     /* get Fiscal Year Begin Month */
     select @FYBMO = GLFY.BeginMth, @FYEMO=GLFY.FYEMO
     from GLFY with(nolock)
     where GLFY.GLCo=@GLCo and @BegMonth>=GLFY.BeginMth and @BegMonth<=GLFY.FYEMO
     if @@rowcount=0
     	begin
     	select @ErrorMessage= '**** Fiscal Year End not set up in GLFY ****'
     	goto selectresults
     end
   
    /* check if ending month is in same year as begin month */
     if @EndMonth <@BegMonth or @FYBMO is null
     	begin
     	select @ErrorMessage= '**** End month may not be less than the begin month ****'
     	goto selectresults
     	end
     if @EndMonth > @FYEMO or @FYEMO is null
     	begin
     	select @ErrorMessage= '**** End month is not in the same fiscal year as begin month ****'
     	goto selectresults
     	end
   
   /* ********************************
      Select the Results
      *******************************  */
     
     selectresults:
     
     exec dbo.brptGLTBDDSelect @GLCo, @BegAcct, @EndAcct, @BegMonth,
           @EndMonth, @IncludeInactive, @Source, @Journal, @DetailLevel,
           @FYEMO, @FYBMO, @EndAcctFull, @ErrorMessage

GO
GRANT EXECUTE ON  [dbo].[brptGLTBDD] TO [public]
GO
