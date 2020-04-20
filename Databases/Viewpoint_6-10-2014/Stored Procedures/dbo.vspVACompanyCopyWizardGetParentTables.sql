SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspVACompanyCopyWizardGetParentTables]  
/***********************************************************  
* CREATED BY: Saurabh 04/12/2012  
* MODIFIED BY: Tom J  02/07/2013 - Had to rework the query as it was extremely slow
*              Tom J  04/30/2012 - This was still not doing what we expected. Removed the parameter so the
*                                  Inclusion of dependent tables won't be something we try to conquer in
*                                  The SQL statements. It will return all dependent tables that care about ordering
*                                  And in code we can reorganize as necessary.
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
	@tablesToCheck VARCHAR(MAX)
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
			 , 1 as [Level]
			 , cast('.' + f.KeyName + '.' as varchar(max)) as ReferenceKeyPath
			 , 0 as cycle
		  FROM @keys as f
	INNER JOIN @tables ON f.SourceObjectName = [@tables].TableName 
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
END	 

GO
GRANT EXECUTE ON  [dbo].[vspVACompanyCopyWizardGetParentTables] TO [public]
GO
