SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 9/28/10
-- Description:	Updates the SM Work Order Detail ud columns from the assumed available #INSERTED temp table.
-- =============================================
CREATE PROCEDURE [dbo].[vspSMWorkCompletedDetailUpdate]
	@SMWorkCompletedDetailTableName varchar(128), @Type tinyint, @ColumnsUpdated varbinary(max) = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	--Only insert/update when we have a record of the given type.
	IF (@Type IS NOT NULL AND NOT EXISTS(SELECT 1 FROM #INSERTED WHERE [Type] = @Type))
		RETURN
	
	DECLARE @TableColumns TABLE (ColumnName nvarchar(128), Updated bit)
	
	IF @ColumnsUpdated IS NULL --@ColumnsUpdated not needed for the insert trigger since COLUMNS_UPDATED return all columns updated for inserts
	BEGIN
		INSERT @TableColumns
		SELECT name, 1
		FROM sys.columns
		WHERE object_id = OBJECT_ID(@SMWorkCompletedDetailTableName) AND is_identity = 0
	END
	ELSE
	BEGIN
		DECLARE @WorkCompletedColumnsUpdated TABLE (ColumnsUpdated nvarchar(128))
		
		INSERT @WorkCompletedColumnsUpdated
		SELECT ColumnsUpdated
		FROM dbo.vfColumnsUpdated(@ColumnsUpdated, 'SMWorkCompleted')

		INSERT @TableColumns
		SELECT name, CASE WHEN EXISTS(SELECT 1 FROM @WorkCompletedColumnsUpdated WHERE ColumnsUpdated = name) THEN 1 ELSE 0 END
		FROM sys.columns
		WHERE object_id = OBJECT_ID(@SMWorkCompletedDetailTableName) AND is_identity = 0
		
		--If we don't find any matching columns that were updated then there is nothing in this table to update
		IF NOT EXISTS(SELECT 1 FROM @TableColumns WHERE Updated = 1)
			RETURN
			
		IF EXISTS(SELECT 1 FROM @WorkCompletedColumnsUpdated WHERE ColumnsUpdated = 'IsSession')
		BEGIN
			--If we find that IsSession was updated then the assumption is that that we are either backing up or restoring records
			UPDATE @TableColumns
			SET Updated = 1
		END
	END

	DECLARE @UpdateWorkCompletedDetailSQL nvarchar(max), @listTableColumns varchar(max), @insertedTableColumns varchar(max), @tableColumnsUpdatedFromInserted varchar(max), @startBlockComment char(2), @endBlockComment char(2), @joinClause varchar(max)
	
	SELECT @startBlockComment = '/*', @endBlockComment = '*/',
		@joinClause = '#INSERTED.WorkOrder = TableToJoin.WorkOrder AND #INSERTED.WorkCompleted = TableToJoin.WorkCompleted AND #INSERTED.SMCo = TableToJoin.SMCo AND #INSERTED.IsSession = TableToJoin.IsSession'

	--Build the update strings. When the IsSession is updated include all columns since this is our mechanism for overwritting backup records.
	SELECT @tableColumnsUpdatedFromInserted = 
			CASE WHEN Updated = 1 THEN dbo.vfSMBuildString(@tableColumnsUpdatedFromInserted, '[' + ColumnName + '] = #INSERTED.[' + ColumnName + ']', ', ')
				ELSE @tableColumnsUpdatedFromInserted
			END,
		@listTableColumns = dbo.vfSMBuildString(@listTableColumns, '[' + ColumnName + ']', ', '),
		@insertedTableColumns = dbo.vfSMBuildString(@insertedTableColumns, '#INSERTED.[' + ColumnName + ']', ', ')
	FROM @TableColumns
	IF @@rowcount <> 0
	BEGIN
		SET @UpdateWorkCompletedDetailSQL = N'
		--Capture the records that are updated so that we know which ones we need to insert
		DECLARE @WorkCompletedUpdated TABLE
		(
			WorkOrder int,
			WorkCompleted int,
			SMCo bCompany,
			IsSession bit
		)

		--Check to see if any of the records for the given type does EXIST in the table to update
		IF EXISTS(SELECT 1 FROM #INSERTED INNER JOIN dbo.' + @SMWorkCompletedDetailTableName + ' TableToJoin ON ' + @joinClause + ')
		BEGIN
			UPDATE TableToJoin
			SET /*<updateColumns></updateColumns>*/
			OUTPUT INSERTED.WorkOrder, INSERTED.WorkCompleted, INSERTED.SMCo, INSERTED.IsSession
				INTO @WorkCompletedUpdated
			FROM dbo.' + @SMWorkCompletedDetailTableName + ' TableToJoin
				INNER JOIN #INSERTED ON ' + @joinClause + '
		END

		INSERT INTO dbo.' + @SMWorkCompletedDetailTableName + ' (/*<columns></columns>*/)
		SELECT /*<insertedColumns></insertedColumns>*/
		FROM #INSERTED
			LEFT JOIN @WorkCompletedUpdated TableToJoin ON ' + @joinClause + '
		WHERE TableToJoin.WorkCompleted IS NULL AND (@Type IS NULL OR #INSERTED.[Type] = @Type)'
		
		SELECT @tableColumnsUpdatedFromInserted = @endBlockComment + @tableColumnsUpdatedFromInserted + @startBlockComment,
			@listTableColumns = @endBlockComment + @listTableColumns + @startBlockComment,
			@insertedTableColumns = @endBlockComment + @insertedTableColumns + @startBlockComment
		
		SET @UpdateWorkCompletedDetailSQL = dbo.vfSMReplaceText(@UpdateWorkCompletedDetailSQL, @tableColumnsUpdatedFromInserted, 'updateColumns')
		
		SET @UpdateWorkCompletedDetailSQL = dbo.vfSMReplaceText(@UpdateWorkCompletedDetailSQL, @listTableColumns, 'columns')
		
		SET @UpdateWorkCompletedDetailSQL = dbo.vfSMReplaceText(@UpdateWorkCompletedDetailSQL, @insertedTableColumns, 'insertedColumns')
		
		EXEC sp_executesql @UpdateWorkCompletedDetailSQL, N'@Type tinyint', @Type = @Type
	END
END
GO
GRANT EXECUTE ON  [dbo].[vspSMWorkCompletedDetailUpdate] TO [public]
GO
