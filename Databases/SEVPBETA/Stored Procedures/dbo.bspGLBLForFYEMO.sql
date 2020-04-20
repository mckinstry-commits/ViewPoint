SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspGLBLForFYEMO    Script Date: 8/28/99 9:34:40 AM ******/
CREATE    PROC [dbo].[bspGLBLForFYEMO]
    @GLCo bCompany,
    @GLAcct bGLAcct,
    @FYEMO bMonth
AS
   
SET nocount ON
   /*
   Select L.Mth, L.NetActivity from bGLBL L, bGLFY Y  
          where L.GLCo= @GLCo and L.GLAcct= @GLAcct and L.Mth>=Y.BeginMth and L.Mth<= 
   	@FYEMO and Y.GLCo=L.GLCo and Y.FYEMO= @FYEMO 
   */
SELECT  L.Mth,
        ABS(L.NetActivity) AS 'NetActivity',
        CASE WHEN L.NetActivity < 0 THEN 'Cr'
             WHEN L.NetActivity = 0 THEN NULL
             ELSE 'Dr'
        END AS 'DrCr'
FROM    dbo.bGLBL L
        JOIN bGLFY Y ON	 Y.GLCo = L.GLCo  
						AND L.Mth >= Y.BeginMth
WHERE   L.GLCo = @GLCo
        AND L.GLAcct = @GLAcct
        AND L.Mth <= @FYEMO
        AND Y.FYEMO = @FYEMO

GO
GRANT EXECUTE ON  [dbo].[bspGLBLForFYEMO] TO [public]
GO
