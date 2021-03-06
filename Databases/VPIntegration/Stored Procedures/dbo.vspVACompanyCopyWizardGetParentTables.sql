SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspVACompanyCopyWizardGetParentTables]  
/***********************************************************  
* CREATED BY: Saurabh 04/12/2012  
* MODIFIED BY: Tom J  02/07/2013 - Had to rework the query as it was extremely slow
*  
* Usage:  
* Used by Company Copy Wizard to get the order of tables to copy, so FK constraints are satisfied  
*  
* Input params:  
* @tablesToCheck   comma delimited list of table names to check for FK constraints  
* @addDependents  flag to include dependent tables
* 
* Output params: none, data table  
*  
*****************************************************/  
  
(  
 @tablesToCheck VARCHAR(MAX),@addDependents bYN = 'Y' 
)  
AS  
BEGIN  
 SET NOCOUNT ON;  
 DECLARE @tables TABLE  
 (  
  TableName VARCHAR(128) NULL  
 );  
   
 INSERT INTO @tables SELECT Names FROM dbo.vfTableFromArray(@tablesToCheck);  

 DECLARE @keys TABLE  
 (
  KeyName sysname,
  SourceObjectName sysname, 
  ReferencedName sysname, 
  SourceObjectId int,
  ReferencedId int
 );  

INSERT INTO @keys SELECT DISTINCT k.name AS KeyName
								, OBJECT_NAME(k.parent_object_id) AS SourceObjectName
								, OBJECT_NAME(k.referenced_object_id) AS ReferencedName
								, k.parent_object_id As SourceObjectId
								, k.referenced_object_id AS ReferencedId 
   FROM sys.foreign_keys k
--   JOIN sys.foreign_key_columns kc ON k.object_id = kc.constraint_object_id
  WHERE OBJECT_NAME(k.parent_object_id) NOT LIKE 'p%' AND OBJECT_NAME(k.referenced_object_id) NOT LIKE 'p%' 
   
 IF (@addDependents='Y')  
 BEGIN  
  WITH ParentReferences  
  AS  
  (  
	select f.SourceObjectId
	     , f.SourceObjectName
	     , f.ReferencedId
	     , f.ReferencedName
	     , f.KeyName as ForeignKey
	     , f.KeyName as SourceKey
	     , 0 as [Level]
	     , cast('.' + f.KeyName + '.' as varchar(max)) as ReferenceKeyPath
	     , 0 as cycle
	  FROM @keys AS f
UNION ALL  
   --Recursive member  
	SELECT f.SourceObjectId
	     , f.SourceObjectName
	     , f.ReferencedId 
	     , f.ReferencedName
	     , f.KeyName
	     , ParentReferences.SourceKey
	     , ParentReferences.[Level] + 1 as [Level]
	     , cast(ParentReferences.ReferenceKeyPath + cast(f.KeyName + '.' as varchar(max)) as varchar(max)) as ReferenceKeyPath
	     , case when ParentReferences.ReferenceKeyPath like '%.' + cast(f.KeyName as varchar(max)) + '.%' then 1 else 0 end as cycle
      FROM ParentReferences   
INNER JOIN @keys f 
        ON ParentReferences.ReferencedId = f.SourceObjectId
       AND ParentReferences.cycle = 0
	)  

    select ReferencedName, max([Level]) 
      from ParentReferences
INNER JOIN DDTables ON ReferencedName = DDTables.TableName AND CopyTable='Y'  
  group by ReferencedName
  order by max([Level]) desc
 END  
 ELSE  
 BEGIN  
  WITH ParentReferences(ObjectName, ParentName, ParentId, [Level])  
  AS  
  (  
   --anchor member  
   --parent_object_id in foreign_key_columns is the table that the FK constraint is on  
   --referenced_object_id is the table that has the FK depends on  
   SELECT OBJECT_NAME(parent_object_id) AS ObjectName,  
     OBJECT_NAME(referenced_object_id) AS ParentName,  
     referenced_object_id AS ParentId,  
     1 AS [Level]  
   FROM sys.foreign_key_columns  
   INNER JOIN @tables ON OBJECT_NAME(sys.foreign_key_columns.parent_object_id) = [@tables].TableName 
   INNER JOIN  DDTables ON OBJECT_NAME(referenced_object_id)=DDTables.TableName AND CopyTable='Y'     
   WHERE --avoid recursive overflow w/ self-referential tables:  
     referenced_object_id <> parent_object_id   
     
   UNION ALL  
     
   --Recursive member  
   SELECT OBJECT_NAME(parent_object_id) AS ObjectName,  
     OBJECT_NAME(referenced_object_id) AS ParentName,  
     referenced_object_id AS ParentId,  
     [Level] + 1  AS [Level]  
   FROM sys.foreign_key_columns  
   INNER JOIN ParentReferences ON ParentReferences.ParentId = sys.foreign_key_columns.parent_object_id   
   INNER JOIN  DDTables ON OBJECT_NAME(referenced_object_id)=DDTables.TableName AND CopyTable='Y'  
             AND  OBJECT_NAME(referenced_object_id) <> ObjectName  
             AND  referenced_object_id <> parent_object_id  
  )  
    
  SELECT DISTINCT a.ParentName ,a.[Level]  
  FROM ParentReferences AS a  
  --use < in the join to get the parent lowest in the hierarchy  
  LEFT OUTER JOIN ParentReferences AS b ON a.ParentName = b.ParentName AND a.[Level] < b.[Level]  
  WHERE b.ParentName IS NULL AND a.ParentName IN (SELECT TableName FROM @tables)  
   ORDER BY [Level]  
  OPTION (MAXRECURSION 1000)  
 END  
END  
    
GO
GRANT EXECUTE ON  [dbo].[vspVACompanyCopyWizardGetParentTables] TO [public]
GO
