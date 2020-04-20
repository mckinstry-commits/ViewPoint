SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jacob Van Houten
-- Create date: 6/7/11
-- Description:	This function is intended to be called from a trigger on a view or table. 
--				By passing in the return value of the COLUMNS_UPDATED() function and the name of the table or view that the trigger is for
--				a table of column names are returned that are all the columns that were updated in the insert or update statement.
-- =============================================
CREATE FUNCTION [dbo].[vfColumnsUpdated]
(	
	@ColumnsUpdated varbinary(max), @TableOrViewName nvarchar(128)
)
RETURNS TABLE 
AS
RETURN 
(
	SELECT COLUMN_NAME AS ColumnsUpdated
    FROM INFORMATION_SCHEMA.COLUMNS Field
    WHERE TABLE_NAME = @TableOrViewName AND (@ColumnsUpdated = 0x0 OR --If @ColumnsUpdated = 0x0 then the function is being run from a delete trigger and all the columns are affected
		sys.fn_IsBitSetInBitmask(@ColumnsUpdated, COLUMNPROPERTY(OBJECT_ID(TABLE_SCHEMA + '.' + TABLE_NAME), COLUMN_NAME, 'ColumnID')) <> 0)
)
GO
GRANT SELECT ON  [dbo].[vfColumnsUpdated] TO [public]
GO
