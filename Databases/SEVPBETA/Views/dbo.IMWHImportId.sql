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
CREATE VIEW [dbo].[IMWHImportId]
AS
SELECT IMWH.ImportId as ImportId, HQBC.Status as Status
FROM IMWH IMWH with (nolock) 
join IMBC IMBC with (nolock) on IMBC.ImportId = IMWH.ImportId 
left join HQBC HQBC with (nolock) on HQBC.Co = IMBC.Co and HQBC.Mth = IMBC.Mth and HQBC.BatchId = IMBC.BatchId
GROUP BY IMWH.ImportId, HQBC.Status

GO
GRANT SELECT ON  [dbo].[IMWHImportId] TO [public]
GRANT INSERT ON  [dbo].[IMWHImportId] TO [public]
GRANT DELETE ON  [dbo].[IMWHImportId] TO [public]
GRANT UPDATE ON  [dbo].[IMWHImportId] TO [public]
GO
