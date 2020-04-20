SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

 
  
   
   
   
   /*****************************************
   * Created By:
   * Modfied By:
   *
   * Provides a view of PM Drawing Log Revisions.
   * used in PM Transmittals as a lookup for drawing logs.
   *
   *****************************************/
    
   
   CREATE  VIEW [dbo].[PMDGUnionPMDR]
   AS
   SELECT PMCo, Project, DrawingType, Drawing, 'Rev'=null, Description
   FROM dbo.PMDG
   UNION
   SELECT PMCo, Project, DrawingType, Drawing, Rev, Description
   from dbo.PMDR
    
    
    
   
   
   
  
 




GO
GRANT SELECT ON  [dbo].[PMDGUnionPMDR] TO [public]
GRANT INSERT ON  [dbo].[PMDGUnionPMDR] TO [public]
GRANT DELETE ON  [dbo].[PMDGUnionPMDR] TO [public]
GRANT UPDATE ON  [dbo].[PMDGUnionPMDR] TO [public]
GO
