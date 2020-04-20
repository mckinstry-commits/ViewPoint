SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 9/28/10
-- Description:	Updates the SM Work Order Detail ud columns from the assumed available #INSERTED temp table.
-- Modified:	4/29/13  JVH TFS-44860 Updated check to see if work completed is part of an invoice
--				5/30/13 TFS-44858 Modified to support changes to the SM Invoice
-- =============================================
CREATE PROCEDURE [dbo].[vspSMWorkCompletedDetailUpdate]
	@SMWorkCompletedDetailTableName varchar(128), @Type tinyint, @JoinClause varchar(max), @ColumnsUpdated varbinary(max) = NULL
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
	END

	DECLARE @UpdateWorkCompletedDetailSQL nvarchar(max), @listTableColumns varchar(max), @insertedTableColumns varchar(max), @tableColumnsUpdatedFromInserted varchar(max)

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
		UPDATE ' + @SMWorkCompletedDetailTableName + '
		SET ' + @tableColumnsUpdatedFromInserted + '
		FROM dbo.' + @SMWorkCompletedDetailTableName + '
			INNER JOIN #INSERTED ON ' + @JoinClause + '

		INSERT dbo.' + @SMWorkCompletedDetailTableName + ' (' + @listTableColumns + ')
		SELECT ' + @insertedTableColumns + '
		FROM #INSERTED
			LEFT JOIN ' + @SMWorkCompletedDetailTableName + ' ON ' + @JoinClause + '
		WHERE ' + @SMWorkCompletedDetailTableName + '.WorkCompleted IS NULL AND (@Type IS NULL OR #INSERTED.[Type] = @Type)'

		EXEC sp_executesql @UpdateWorkCompletedDetailSQL, N'@Type tinyint', @Type = @Type
	END
END
GO
GRANT EXECUTE ON  [dbo].[vspSMWorkCompletedDetailUpdate] TO [public]
GO
