SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[BITargetDDFILookup] as 

-- company from DDFH
SELECT -1        AS Seq, 
       ViewName  AS ViewName, 
       CoColumn  AS ColumnName, 
       'Company' AS [Description], 
       Form      AS [TargetType] 
FROM   DDFHShared 
WHERE  ViewName IS NOT NULL 
       AND CoColumn IS NOT NULL 
       
UNION ALL 

-- DDFI entries that are not computed
SELECT Seq, 
       ViewName, 
       ColumnName, 
       [Description], 
       Form AS [TargetType] 
FROM   DDFIShared 
WHERE  Computed = 'N' 
	   AND ViewName IS NOT NULL 
       AND ColumnName IS NOT NULL 
		
GO
GRANT SELECT ON  [dbo].[BITargetDDFILookup] TO [public]
GRANT INSERT ON  [dbo].[BITargetDDFILookup] TO [public]
GRANT DELETE ON  [dbo].[BITargetDDFILookup] TO [public]
GRANT UPDATE ON  [dbo].[BITargetDDFILookup] TO [public]
GO
