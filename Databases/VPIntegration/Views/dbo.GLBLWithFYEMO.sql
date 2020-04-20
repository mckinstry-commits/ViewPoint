SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
   
CREATE view [dbo].[GLBLWithFYEMO]
/**************************************************
* Created: 08/24/06
* Modified: 
*
* Provides a view of GL Monthly Account Balances that includes FYEMO.  Used
* by the GL Prior Years Activity Maintenance form.
*
***************************************************/

as

Select top 100 percent *, dbo.vfGLGetFYEMO(GLCo, Mth) as FYEMO from GLBL (nolock)
order by GLCo, GLAcct, Mth


    
   
   
   
   
  
 



GO
GRANT SELECT ON  [dbo].[GLBLWithFYEMO] TO [public]
GRANT INSERT ON  [dbo].[GLBLWithFYEMO] TO [public]
GRANT DELETE ON  [dbo].[GLBLWithFYEMO] TO [public]
GRANT UPDATE ON  [dbo].[GLBLWithFYEMO] TO [public]
GO
