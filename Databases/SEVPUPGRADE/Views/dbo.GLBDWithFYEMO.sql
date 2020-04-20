SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
   
CREATE view [dbo].[GLBDWithFYEMO]
/**************************************************
* Created: 08/28/06
* Modified: 
*
* Provides a view of GL Monthly Budget Amounts that includes FYEMO.  Used
* by the GL Monthly Budget Maintenance form.
*
***************************************************/

as

Select top 100 percent *, dbo.vfGLGetFYEMO(GLCo, Mth) as FYEMO from GLBD (nolock)
order by GLCo, GLAcct, BudgetCode, Mth


    
   
   
   
   
  
 



GO
GRANT SELECT ON  [dbo].[GLBDWithFYEMO] TO [public]
GRANT INSERT ON  [dbo].[GLBDWithFYEMO] TO [public]
GRANT DELETE ON  [dbo].[GLBDWithFYEMO] TO [public]
GRANT UPDATE ON  [dbo].[GLBDWithFYEMO] TO [public]
GO
