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
CREATE VIEW [dbo].[IMKVImportId]
AS
SELECT a.ImportId, a.ImportTemplate--, a.Value
FROM dbo.bIMKV AS a
GROUP BY a.ImportId, a.ImportTemplate--, a.Value

GO
GRANT SELECT ON  [dbo].[IMKVImportId] TO [public]
GRANT INSERT ON  [dbo].[IMKVImportId] TO [public]
GRANT DELETE ON  [dbo].[IMKVImportId] TO [public]
GRANT UPDATE ON  [dbo].[IMKVImportId] TO [public]
GO
