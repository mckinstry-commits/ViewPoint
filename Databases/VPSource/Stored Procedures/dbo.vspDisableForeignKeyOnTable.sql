SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/************************************************************************
* CREATED:	AR 9/14/2010    
* MODIFIED:	
*
* Purpose: Disables Foreign Keys related to a table

* returns 1 and error msg if failed
*
*************************************************************************/
CREATE PROCEDURE dbo.vspDisableForeignKeyOnTable 
	@TableName sysname,
	@Enable bit = 1
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @SQLStr varchar(MAX)
	DECLARE @tblFKs TABLE (TabName sysname, FKName sysname)
	DECLARE @FKName sysname,
			@TabName sysname
	
	
    BEGIN TRY
		-- find all foreignkey references
		INSERT INTO @tblFKs (TabName, FKName)
		SELECT OBJECT_NAME(fk.parent_object_id), fk.name 
		FROM sys.foreign_keys AS fk
		WHERE fk.referenced_object_id = OBJECT_ID(@TableName)
			OR fk.parent_object_id =  OBJECT_ID(@TableName)
		
		-- loop through the keys		
		WHILE EXISTS (SELECT 1 FROM  @tblFKs)
		BEGIN
			SELECT TOP 1 @FKName = FKName,
						@TabName = TabName
			FROM @tblFKs AS tfk
			
			-- create string to enable or disable the constraint
			IF @Enable = 0
			BEGIN
				SET @SQLStr = 'ALTER TABLE ' + @TabName + ' NOCHECK CONSTRAINT ' + @FKName
			END
			ELSE
			BEGIN 
				SET @SQLStr = 'ALTER TABLE ' + @TabName + ' CHECK CONSTRAINT ' + @FKName
			END
		
			EXEC (@SQLStr)
			
			DELETE @tblFKs WHERE FKName = @FKName AND TabName = @TabName
		END 
    END TRY
    BEGIN CATCH
			DECLARE @ErrMsg varchar(MAX)
			SET @ErrMsg = ERROR_MESSAGE()
			IF @@TRANCOUNT > 0 BEGIN ROLLBACK TRAN END
			RAISERROR (@ErrMsg,15,1)
    END CATCH
    
    RETURN (0)
END

GO
GRANT EXECUTE ON  [dbo].[vspDisableForeignKeyOnTable] TO [public]
GO
