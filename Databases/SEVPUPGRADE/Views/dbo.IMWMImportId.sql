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
CREATE VIEW [dbo].[IMWMImportId]
AS
SELECT a.ImportId
FROM dbo.bIMWM AS a
GROUP BY a.ImportId

GO
GRANT SELECT ON  [dbo].[IMWMImportId] TO [public]
GRANT INSERT ON  [dbo].[IMWMImportId] TO [public]
GRANT DELETE ON  [dbo].[IMWMImportId] TO [public]
GRANT UPDATE ON  [dbo].[IMWMImportId] TO [public]
GO
