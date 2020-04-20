SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*****************************************
   * Created By: DANF
   * Modfied By:
   *
   * Provides a view of ImportId's
   *
   *****************************************/
CREATE VIEW [dbo].[IMPRImportId]
AS
SELECT a.ImportId
FROM dbo.bIMPR AS a
GROUP BY a.ImportId


GO
GRANT SELECT ON  [dbo].[IMPRImportId] TO [public]
GRANT INSERT ON  [dbo].[IMPRImportId] TO [public]
GRANT DELETE ON  [dbo].[IMPRImportId] TO [public]
GRANT UPDATE ON  [dbo].[IMPRImportId] TO [public]
GRANT SELECT ON  [dbo].[IMPRImportId] TO [Viewpoint]
GRANT INSERT ON  [dbo].[IMPRImportId] TO [Viewpoint]
GRANT DELETE ON  [dbo].[IMPRImportId] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[IMPRImportId] TO [Viewpoint]
GO
