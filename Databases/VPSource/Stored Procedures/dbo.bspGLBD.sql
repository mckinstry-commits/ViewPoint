SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspGLBD    Script Date: 8/28/99 9:34:40 AM ******/
CREATE    PROC [dbo].[bspGLBD]
   /********************************************
    * Created: ??
    * Modified: GG 08/06/01 - cleanup, add comments
				AR 11/29/10 - #142278 - removing old style joins replace with ANSI correct form
    *
    *  Used to return budget amounts for a particular GL Company, GL Account,
    *	Budget Code, and Fiscal Year 
    *
    * Inputs:
    *	@GLCO			GL Company
    *	@GLAcct			GL Account
    *	@BudgetCode		Budget Code
    *	@FYEMO			Fiscal Year ending month
    *
    * Output:
    *	Resultset of Month and Budget Amounts
    *
    ******************************************************************/
(
  @GLCo bCompany,
  @GLAcct bGLAcct,
  @BudgetCode bBudgetCode,
  @FYEMO bMonth
)
AS 
SET nocount ON
   /*
   Select D.Mth, D.BudgetAmt
   from bGLBD D,bGLFY Y  
   where D.GLCo=@GLCo and D.GLAcct=@GLAcct and D.BudgetCode=@BudgetCode
   	and D.Mth>=Y.BeginMth and D.Mth<=@FYEMO and Y.GLCo=D.GLCo and Y.FYEMO=@FYEMO
   */
   
SELECT  D.Mth,
        ABS(D.BudgetAmt) AS 'BudgetAmt',
        CASE WHEN D.BudgetAmt < 0 THEN 'Cr'
             WHEN D.BudgetAmt = 0 THEN NULL
             ELSE 'Dr'
        END AS 'DrCr'
FROM    dbo.bGLBD D
        JOIN bGLFY Y ON Y.GLCo = D.GLCo
						AND D.Mth >= Y.BeginMth
WHERE   D.GLCo = @GLCo
        AND D.GLAcct = @GLAcct
        AND D.BudgetCode = @BudgetCode
        AND D.Mth <= @FYEMO
        AND Y.FYEMO = @FYEMO

GO
GRANT EXECUTE ON  [dbo].[bspGLBD] TO [public]
GO
