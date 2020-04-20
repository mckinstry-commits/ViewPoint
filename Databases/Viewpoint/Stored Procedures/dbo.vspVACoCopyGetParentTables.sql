SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[vspVACoCopyGetParentTables]

/***********************************************************
* CREATED BY: CC 10/19/10 Issue #140575
* MODIFIED By : AR 4/13/2011 TK-04194 - removing circular references
*				
*		
* Usage:
*	Used by Company copy to get the order of tables to copy, so FK constraints are satisfied
*
* Input params:
*	@tablesToCheck			comma delimited list of table names to check for FK constraints
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
	
	
	WITH ParentReferences(ObjectName, ParentName, ParentId, [Level])
	AS
	(
		--anchor member
		--parent_object_id in foreign_key_columns is the table that the FK constraint is on
		--referenced_object_id is the table that has the FK depends on
		SELECT	OBJECT_NAME(parent_object_id) AS ObjectName,
				OBJECT_NAME(referenced_object_id) AS ParentName,
				referenced_object_id AS ParentId,
				1 AS [Level]
		FROM sys.foreign_key_columns
		INNER JOIN @tables ON OBJECT_NAME(sys.foreign_key_columns.parent_object_id) = [@tables].TableName
		WHERE	--avoid recursive overflow w/ self-referential tables:
				referenced_object_id <> parent_object_id 
		
		UNION ALL
		
		--Recursive member
		SELECT	OBJECT_NAME(parent_object_id) AS ObjectName,
				OBJECT_NAME(referenced_object_id) AS ParentName,
				referenced_object_id AS ParentId,
				[Level] + 1  AS [Level]
		FROM sys.foreign_key_columns
		INNER JOIN ParentReferences ON ParentReferences.ParentId = sys.foreign_key_columns.parent_object_id	
												--TK-04194 - removing circular references and self references
												AND	 OBJECT_NAME(referenced_object_id) <> ObjectName
												AND	 referenced_object_id <> parent_object_id
	)
	SELECT	DISTINCT
			a.ParentName ,
			a.[Level]
	FROM ParentReferences AS a
	--use < in the join to get the parent lowest in the hierarchy
	LEFT OUTER JOIN ParentReferences AS b ON a.ParentName = b.ParentName AND a.[Level] < b.[Level]
	WHERE b.ParentName IS NULL
	ORDER BY [Level]
	OPTION (MAXRECURSION 1000)
	
END

GO
GRANT EXECUTE ON  [dbo].[vspVACoCopyGetParentTables] TO [public]
GO
