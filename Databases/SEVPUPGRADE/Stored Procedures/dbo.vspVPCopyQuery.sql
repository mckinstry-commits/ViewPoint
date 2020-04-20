SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspVPCopyQuery]
/***********************************************************
* CREATED BY:   CC 09/24/2008
* MODIFIED BY:  CC 10/13/2009 - Issue #132545 - Add column to support datatype definition for My Viewpoint queries
*				HH 5/31/2012 - TK-15193 added ExcludeFromQuery field
*
* Usage: Used by VA to copy a VP Query
*	
*
* Input params:
*	@SourceQuery
*	@DestinationQuery
*
* Output params:
*	
*
* Return code:
*
*	
************************************************************/
@SourceQuery VARCHAR(50) = NULL,
@DestinationQuery VARCHAR(50) = NULL,
@msg VARCHAR(255) OUTPUT

AS
BEGIN
SET NOCOUNT ON

IF EXISTS (SELECT TOP 1 1 FROM VPGridQueries WHERE UPPER(QueryName) = UPPER(@DestinationQuery))
	BEGIN
		SELECT @msg = 'New query name cannot be the same as existing query name.'
		RETURN
	END

	INSERT INTO VPGridQueries (QueryName, QueryTitle, QueryDescription, Query, IsStandard, QueryType)
		SELECT @DestinationQuery,		  QueryTitle, QueryDescription, Query, 'N', QueryType
		FROM VPGridQueries
		WHERE QueryName = @SourceQuery;

	INSERT INTO VPGridQueryParameters (QueryName, Seq, ColumnName, ParameterName, Comparison, DataType, [Value], Operator, IsVisible, [Description], DefaultType, DefaultOrder, InputType, Prec, [Lookup])
		SELECT @DestinationQuery,				  Seq, ColumnName, ParameterName, Comparison, DataType, [Value], Operator, IsVisible, [Description], DefaultType, DefaultOrder, InputType, Prec, [Lookup]
		FROM VPGridQueryParameters
		WHERE QueryName = @SourceQuery;

	INSERT INTO VPGridColumns (QueryName, ColumnName, DefaultOrder, VisibleOnGrid, Datatype, ExcludeFromAggregation, ExcludeFromQuery)
		SELECT @DestinationQuery,		  ColumnName, DefaultOrder, VisibleOnGrid, Datatype, ExcludeFromAggregation, ExcludeFromQuery
		FROM VPGridColumns
		WHERE QueryName = @SourceQuery;

	INSERT INTO VPGridQueryAssociation (QueryName, TemplateName, Active)
		SELECT @DestinationQuery,				   TemplateName, Active
		FROM VPGridQueryAssociation
		WHERE QueryName = @SourceQuery;
END


GO
GRANT EXECUTE ON  [dbo].[vspVPCopyQuery] TO [public]
GO
