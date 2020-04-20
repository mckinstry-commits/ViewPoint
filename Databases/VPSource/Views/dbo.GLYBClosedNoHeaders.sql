SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  view [dbo].[GLYBClosedNoHeaders] 
   /**************************************************
   * Created: ??
   * Modified: 
   *
   * Notes:  
   * 4/4/05 - DC #26761
   *	I could not find where this view is being used.  
   *
   ***************************************************/
    as select y.* from GLYB y 
    INNER JOIN bGLAC a 
    ON y.GLAcct = a.GLAcct AND y.GLCo = a.GLCo
    where y.FYEMO <= (select LastMthGLClsd from bGLCO c where c.GLCo=y.GLCo) AND a.AcctType <> 'H'

GO
GRANT SELECT ON  [dbo].[GLYBClosedNoHeaders] TO [public]
GRANT INSERT ON  [dbo].[GLYBClosedNoHeaders] TO [public]
GRANT DELETE ON  [dbo].[GLYBClosedNoHeaders] TO [public]
GRANT UPDATE ON  [dbo].[GLYBClosedNoHeaders] TO [public]
GO
