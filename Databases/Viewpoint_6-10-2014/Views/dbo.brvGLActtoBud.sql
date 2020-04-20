SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   CREATE  view  [dbo].[brvGLActtoBud] as
   select GLBD.GLCo, Type=1,GLBD.GLAcct, GLBD.BudgetCode, GLBD.Mth, GLBD.BudgetAmt, NetActivity=null
   from GLBD
   
   Union All
   
   select GLBL.GLCo,2, GLBL.GLAcct, null, GLBL.Mth, null, GLBL.NetActivity
   
   from GLBL
   
   
   
  
 



GO
GRANT SELECT ON  [dbo].[brvGLActtoBud] TO [public]
GRANT INSERT ON  [dbo].[brvGLActtoBud] TO [public]
GRANT DELETE ON  [dbo].[brvGLActtoBud] TO [public]
GRANT UPDATE ON  [dbo].[brvGLActtoBud] TO [public]
GRANT SELECT ON  [dbo].[brvGLActtoBud] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvGLActtoBud] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvGLActtoBud] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvGLActtoBud] TO [Viewpoint]
GO
