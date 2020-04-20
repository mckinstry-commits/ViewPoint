SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspVPInsertQueryColumn]
		/***********************************************************
		* CREATED BY:   CC 09/24/2008
		* MODIFIED BY:  HH 5/31/2012 TK-15193 added @ExcludeFromQuery
		*				HH 10/12/2012 - TK-18457 added IsNotifierKeyField
		*
		* Usage: Inserts new columns associated with a query
		*	
		*
		* Input params:
		*	@QueryName
		*	@ColumnName
		*	@DefaultOrder
		*	@ShowOnGrid
		*
		* Output params:
		*	
		*
		* Return code:
		*
		*	
		************************************************************/

		@QueryName VARCHAR(50) = null,
		@ColumnName VARCHAR(150) = null,
		@DefaultOrder int,
		@ShowOnGrid bYN = 'Y',
		@ExcludeFromQuery bYN = 'N',
		@IsNotifierKeyField bYN = 'N'
AS

SET NOCOUNT ON

IF NOT EXISTS(SELECT TOP 1 1 FROM VPGridColumns WHERE QueryName = @QueryName AND ColumnName = @ColumnName)
	INSERT INTO VPGridColumns (QueryName, ColumnName, DefaultOrder, VisibleOnGrid, ExcludeFromQuery, IsNotifierKeyField)
		VALUES
		(@QueryName, @ColumnName, @DefaultOrder, @ShowOnGrid, @ExcludeFromQuery, @IsNotifierKeyField)


GO
GRANT EXECUTE ON  [dbo].[vspVPInsertQueryColumn] TO [public]
GO
