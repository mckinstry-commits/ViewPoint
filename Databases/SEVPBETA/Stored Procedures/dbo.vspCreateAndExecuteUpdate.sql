SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Create date: Jacob VH 12/11/08
-- Description:	Used typically by INSTEAD OF UPDATE triggers
--		This procedure will generate and execute an update statement that will update 
--		all columns for the given table to update from the given table to update from.
-- Requirements: 
--	1) A table must exist with the names given in @tableToUpdateName and @tableToUpdateFromName
--	2) The table that is being used to update from must have ALL the same column names 
--		with the EXACT same column names as the table bein updated
-- IMPORTANT NOTE: NO EXCEPTION HANDLING IS DONE HERE. YOU MUST HANDLE IT YOURSELF
-- =============================================

CREATE PROCEDURE [dbo].[vspCreateAndExecuteUpdate]
	(@tableToUpdateName VARCHAR(MAX), 
	@tableToUpdateFromName VARCHAR(MAX), 
	@joinClause VARCHAR(MAX))
	-- It is important to run as viewpointcs because the chain of permissions is lost when running
	-- dynamic sql. When using this stored procedure recognize that the after triggers will exececute as viewpointcs
	-- instead of whoever logged in. This can be changed by executing EXECUTE AS USER = ORIGINAL_LOGIN()
WITH EXECUTE AS 'viewpointcs' AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	-- Raise an error if the arguments are null
	IF @tableToUpdateName IS NULL OR @tableToUpdateFromName IS NULL OR @joinClause IS NULL
	BEGIN
		RAISERROR('Arguments for vspCreateAndExecuteUpdate cannot be null', 16, 1)
		GOTO VspExit
    END

	DECLARE @SQL NVARCHAR(MAX), @ColumnNames VARCHAR(MAX), @tableToUpdateObjectID VARCHAR(MAX)

	-- Get the object id for the table to update
	SET @tableToUpdateObjectID = OBJECT_ID(@tableToUpdateName)
	
	-- Raise an error when the table does not exist
	IF @tableToUpdateObjectID IS NULL
	BEGIN
		RAISERROR('Table %s can not be updated because it does not exist', 16, 1, @tableToUpdateName)
		GOTO VspExit
    END
    
	SET @ColumnNames = NULL
	
	-- Generate the SQL statement to execute to retrieve all column names from the given table to update
	SET @SQL = 
	'SELECT 
		@InternalColumnNames = CASE WHEN @InternalColumnNames IS NULL 
			THEN ''['' + c.name + ''] = ' + @tableToUpdateFromName + '.['' + c.name + '']''
			ELSE @InternalColumnNames + '', ['' + c.name + ''] = ' + @tableToUpdateFromName + '.['' + c.name + '']'' END
	FROM  
		sys.columns c
	WHERE c.is_identity = 0 AND c.object_id = ' + @tableToUpdateObjectID

	-- Retrieve the column names
	EXECUTE sp_executesql @SQL, N'@InternalColumnNames VARCHAR(MAX) OUTPUT', @InternalColumnNames = @ColumnNames OUTPUT
	
	-- Using the parameters generate the SQL statement to do the actual update
	SET @SQL = 'UPDATE ' + @tableToUpdateName + 
		' SET ' + @ColumnNames + 
		' FROM ' + @tableToUpdateName + ' JOIN ' + @tableToUpdateFromName + ' ON ' + @joinClause

	-- Do the update
	EXECUTE sp_executesql @SQL

	VspExit:
END

GO
GRANT EXECUTE ON  [dbo].[vspCreateAndExecuteUpdate] TO [public]
GO
