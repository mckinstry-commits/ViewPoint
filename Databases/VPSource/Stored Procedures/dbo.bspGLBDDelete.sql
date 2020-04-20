SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspGLBDDelete    Script Date: 8/28/99 9:32:45 AM ******/
   
   CREATE Proc [dbo].[bspGLBDDelete]
   @GLCo  bCompany,
   @GLAcct bGLAcct,
   @BudgetCode bBudgetCode,
   @FYEMO bMonth
   
   as
   
   /*  Stored Proc to delete all Budget amounts for a particular CO acct BC Month*/
   /*  Pass in the Co, Acct, Budget code and the FYEMO and this will return    */
   /*  the Budget amounts for each month in the particular FYEMO               */
   
   set nocount on
   
   Delete GLBD from GLBD D,GLFY Y 
          where D.GLCo=@GLCo and D.GLAcct=@GLAcct and
   	     D.BudgetCode=@BudgetCode and D.Mth>=Y.BeginMth and
   
   
   
   
   
   
   
   	     D.Mth<=@FYEMO and
                Y.GLCo=D.GLCo and Y.FYEMO=@FYEMO

GO
GRANT EXECUTE ON  [dbo].[bspGLBDDelete] TO [public]
GO
