SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vrptHQImplementationRecordCounts]
WITH EXECUTE AS 'viewpointcs'
AS

BEGIN
SET NOCOUNT ON

-- let's get our basic counts
SELECT      DISTINCT wtt.Template, 
                  wtt.Task,
                  wtt.VPName AS FormName, 
            v.name AS ViewName,
            t.name AS TableName,
            p.[rows] AS [RowCount],
            ddt.CoColumn
INTO #CountTables
FROM dbo.vDDTables AS ddt
        JOIN sys.tables AS t ON ddt.TableName = t.name
      JOIN sys.sysdepends AS d ON t.object_id = d.depid
      JOIN sys.views AS v ON v.object_id = d.id
      JOIN sys.partitions AS p ON p.object_id = t.object_id
      JOIN dbo.vDDFH AS FH ON FH.ViewName = v.name
      JOIN dbo.WFTemplateTasks AS wtt ON wtt.VPName = FH.Form
WHERE wtt.Template LIKE '%Impl' OR wtt.Template = 'Startup Guide'


CREATE TABLE #CompanyGroup (TableName VARCHAR(128), Company TINYINT, [RowCount] bigint)

DECLARE @Co VARCHAR(128),
            @TableName VARCHAR(128)
-- if a company table, group it out by co
DECLARE curCountCompany CURSOR FOR 
      SELECT TableName, CoColumn
      FROM #CountTables ct
      WHERE CoColumn IS NOT NULL
OPEN curCountCompany

FETCH NEXT FROM curCountCompany INTO @TableName, @Co

WHILE @@FETCH_STATUS = 0
BEGIN 

      INSERT INTO #CompanyGroup (TableName, Company, [RowCount])
      EXEC ('
               SELECT ''' + @TableName + ''',co.HQCo,COUNT( '+ @TableName + '.' + @Co + ')' +
               'FROM ' + @TableName +
               '  RIGHT JOIN dbo.bHQCO co ON co.HQCo = ' + @TableName + '.' + @Co +
               ' GROUP BY ALL co.HQCo'
            )
            
      --SELECT * FROM #CompanyGroup
      FETCH NEXT FROM curCountCompany INTO @TableName, @Co  
            
END 

CLOSE curCountCompany
DEALLOCATE curCountCompany

SELECT Template, Task, FormName, ViewName,TableName, NULL AS Company, [RowCount]
FROM #CountTables
WHERE CoColumn IS NULL
UNION ALL 
SELECT ct.Template, ct.Task, ct.FormName, ct.ViewName, ct.TableName, cg.Company, cg.[RowCount]
FROM #CountTables ct
      JOIN #CompanyGroup cg ON cg.TableName = ct.TableName


DROP TABLE #CountTables
DROP TABLE #CompanyGroup

END

GO
GRANT EXECUTE ON  [dbo].[vrptHQImplementationRecordCounts] TO [public]
GO
