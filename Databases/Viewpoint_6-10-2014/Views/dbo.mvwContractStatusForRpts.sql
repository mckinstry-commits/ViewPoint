SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE VIEW [dbo].[mvwContractStatusForRpts]
AS 
SELECT DatabaseValue, DisplayValue, ROW_NUMBER()OVER (ORDER BY DatabaseValue)+2 AS OrderBY
FROM dbo.DDCI
WHERE ComboType = 'JCContractStatus'
UNION ALL
SELECT 4, '4-All Exclude Hard Closed', 1
UNION ALL
SELECT 5, '5-All Include Hard Closed', 2
GO
