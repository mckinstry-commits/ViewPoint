SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspGLBLDelete    Script Date: 8/28/99 9:32:45 AM ******/
   
   CREATE Proc [dbo].[bspGLBLDelete]
   @GLCo  bCompany,
   @GLAcct bGLAcct,
   @FYEMO bMonth
   
   as
   
   /*  Stored Proc to delete all entries in GLBL for a particular CO acct & Month*/
   /*  Pass in the Co, Acct and the FYEMO and this will delete the records for that FYEMO*/
   
   set nocount on
   Delete GLBL from GLBL L,GLFY Y 
          where L.GLCo=@GLCo and L.GLAcct=@GLAcct and
   	     L.Mth>=Y.BeginMth and
   	     L.Mth<=@FYEMO and
                Y.GLCo=L.GLCo and Y.FYEMO=@FYEMO

GO
GRANT EXECUTE ON  [dbo].[bspGLBLDelete] TO [public]
GO
