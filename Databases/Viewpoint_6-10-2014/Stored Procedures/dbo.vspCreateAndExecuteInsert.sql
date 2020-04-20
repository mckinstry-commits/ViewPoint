SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Create date: Jacob VH 12/11/08
-- Description:	Used typically by INSTEAD OF INSERT triggers
--		This procedure will generate and execute an insert statement that will insert 
--		all columns for the given table to update from the given table to update from.
-- Requirements: 
--	1) A table must exist with the names given in @tableToInsertName and @tableToInsertFromName
--	2) The table that is being used to insert from must have ALL the same column names 
--		with the EXACT same column names as the table being inserted into
-- IMPORTANT NOTE: NO EXCEPTION HANDLING IS DONE HERE. YOU MUST HANDLE IT YOURSELF
-- =============================================

CREATE PROCEDURE [dbo].[vspCreateAndExecuteInsert]
	(@tableToInsertName VARCHAR(MAX), 
	@tableToInsertFromName VARCHAR(MAX))
	-- It is important to run as viewpointcs because the chain of permissions is lost when running
	-- dynamic sql. When using this stored procedure recognize that the after triggers will exececute as viewpointcs
	-- instead of whoever logged in. This can be changed by executing EXECUTE AS USER = ORIGINAL_LOGIN()
WITH EXECUTE AS 'viewpointcs' AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    DECLARE @SQL NVARCHAR(MAX), @ColumnNames VARCHAR(MAX), @tableToInsertObjectID VARCHAR(MAX)

	SET @ColumnNames = NULL
	
	-- Get the object id for the table to update
	SET @tableToInsertObjectID = OBJECT_ID(@tableToInsertName)
	
	-- Generate the SQL statement to execute to retrieve all column names from the given table to insert into
	SET @SQL = 
	'SELECT 
		@InternalColumnNames = CASE WHEN @InternalColumnNames IS NULL 
			THEN ''['' + c.name + '']''
			ELSE @InternalColumnNames + '', ['' + c.name + '']'' END
	FROM  
		sys.columns c
	WHERE c.is_identity = 0 AND c.object_id = ' + @tableToInsertObjectID

	-- Retrieve the column names
	EXECUTE sp_executesql @SQL, N'@InternalColumnNames VARCHAR(MAX) OUTPUT', @InternalColumnNames = @ColumnNames OUTPUT

	-- Using the parameters generate the SQL statement to do the actual insert
	SET @SQL = 
	'INSERT INTO ' + @tableToInsertName + 
		' (' + @ColumnNames + 
		') SELECT ' + @ColumnNames + 
		' FROM ' + @tableToInsertFromName
		
	-- Do the insert
	EXECUTE sp_executesql @SQL
END

GO
GRANT EXECUTE ON  [dbo].[vspCreateAndExecuteInsert] TO [public]
GO
