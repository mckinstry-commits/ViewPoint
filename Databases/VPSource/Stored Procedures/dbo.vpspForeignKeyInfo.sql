SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 6-16-09
-- Description:	Returns the table and column names for a given foreign key
--				We use the results to return a friendlier message.
-- =============================================
CREATE PROCEDURE [dbo].[vpspForeignKeyInfo]
	@ForeignKeyName AS VARCHAR(60)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT
		ParentTable.name AS ParentTableName,
		ParentColumns.name AS ParentColumnName,
		ReferencedTable.name AS ReferencedTableName,
		ReferencedColumns.name AS ReferencedColumnName
	FROM sys.foreign_keys
		INNER JOIN sys.foreign_key_columns 
			ON sys.foreign_keys.object_id = sys.foreign_key_columns.constraint_object_id
		INNER JOIN sys.tables ParentTable
			ON sys.foreign_key_columns.parent_object_id = ParentTable.object_id 
		INNER JOIN sys.columns ParentColumns
			ON ParentTable.object_id = ParentColumns.object_id 
			AND sys.foreign_key_columns.parent_column_id = ParentColumns.column_id
		INNER JOIN sys.tables ReferencedTable
			ON sys.foreign_key_columns.referenced_object_id = ReferencedTable.object_id 
		INNER JOIN sys.columns ReferencedColumns
			ON ReferencedTable.object_id = ReferencedColumns.object_id 
			AND sys.foreign_key_columns.referenced_column_id = ReferencedColumns.column_id
	WHERE sys.foreign_keys.name = @ForeignKeyName
END

GO
GRANT EXECUTE ON  [dbo].[vpspForeignKeyInfo] TO [VCSPortal]
GO
