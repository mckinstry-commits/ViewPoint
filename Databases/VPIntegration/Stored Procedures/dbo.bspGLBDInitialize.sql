SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspGLBDInitialize    Script Date: 8/28/99 9:32:45 AM ******/
   
   CREATE Proc [dbo].[bspGLBDInitialize]
   @GLCo  bCompany,
   @GLAcct bGLAcct,
   @BudgetCode bBudgetCode,
   @FYEMO bMonth
   
   as
   
   /******************************************************************/
   /** Pass this A GLCo, An Account, Budget code and a FYEMO and it **/
   /** Will initialize GLBD entries. For months from Beg to FYEMO   **/
   /**								 **/
   /** IMPORTANT :							 **/
   /**   this will delete any current entries for GLBD for passed   **/
   /**   criteria.							 **/
   /******************************************************************/
   set nocount on
   
   Declare @BMth bMonth
   Declare @EMth bMonth
   
   Begin Tran
     delete GLBD From GLBD D,GLFY Y where
   	@GLCo=Y.GLCo and Y.FYEMO=@FYEMO and
   	@GLCo=D.GLCo and @GLAcct=D.GLAcct and
           @BudgetCode=D.BudgetCode and
           D.Mth>=Y.BeginMth and D.Mth <=Y.FYEMO
   
     Select @BMth=Y.BeginMth, @EMth=Y.FYEMO from GLFY Y where Y.GLCo=@GLCo and Y.FYEMO=@FYEMO
   
     While @BMth<=@EMth 
      Begin
        Insert into GLBD (GLCo, GLAcct, BudgetCode, Mth, BudgetAmt)
   	    	   Values
   		   (@GLCo, @GLAcct, @BudgetCode, @BMth, 0)
        Select @BMth=dateadd(mm,1,@BMth)
      End
   
   Commit Tran

GO
GRANT EXECUTE ON  [dbo].[bspGLBDInitialize] TO [public]
GO
