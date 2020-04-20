SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  view [dbo].[GLYBClosed] 
   /**************************************************
   * Created: ??
   * Modified: 
   *
   * Notes:  
   * 4/4/05 - DC #26761
   *	I could not find where this view is being used.  
   * 
   ***************************************************/
    as select * from GLYB Y 
    where Y.FYEMO <= (select LastMthGLClsd from GLCO where GLCO.GLCo=Y.GLCo)

GO
GRANT SELECT ON  [dbo].[GLYBClosed] TO [public]
GRANT INSERT ON  [dbo].[GLYBClosed] TO [public]
GRANT DELETE ON  [dbo].[GLYBClosed] TO [public]
GRANT UPDATE ON  [dbo].[GLYBClosed] TO [public]
GRANT SELECT ON  [dbo].[GLYBClosed] TO [Viewpoint]
GRANT INSERT ON  [dbo].[GLYBClosed] TO [Viewpoint]
GRANT DELETE ON  [dbo].[GLYBClosed] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[GLYBClosed] TO [Viewpoint]
GO
