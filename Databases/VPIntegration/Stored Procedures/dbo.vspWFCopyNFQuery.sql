SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspWFCopyNFQuery]
/***********************************************************
* CREATED BY:   CC 08/08/2008
* MODIFIED BY:  CC 05/18/2010 - 139446 - Include event query & is key field in copy
* 
* Usage: Used by WF to copy a Notifier query
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

SET NOCOUNT ON

IF EXISTS (SELECT TOP 1 1 FROM WDQY WHERE UPPER(QueryName) = UPPER(@DestinationQuery))
	BEGIN
		SELECT @msg = 'New query name cannot be the same as existing query name.'
		RETURN
	END

INSERT INTO WDQY (QueryName, [Description], Title, SelectClause, FromWhereClause, [Standard], IsEventQuery, Notes)
	SELECT @DestinationQuery, [Description], Title, SelectClause, FromWhereClause, 'N', IsEventQuery, Notes
	FROM WDQY
	WHERE QueryName = @SourceQuery;

--insert into WDQY takes care of populating WDQF (query fields), then update to carry over is key field status
UPDATE WDQF 
SET IsKeyField = SourceQuery.IsKeyField
FROM WDQF 
INNER JOIN WDQF AS SourceQuery ON	dbo.WDQF.EMailField = SourceQuery.EMailField AND 
									dbo.WDQF.TableColumn = SourceQuery.TableColumn AND 
									SourceQuery.QueryName = @SourceQuery
WHERE WDQF.QueryName = @DestinationQuery;

INSERT INTO WDQP (QueryName, [Param], [Description])
	SELECT @DestinationQuery, [Param], [Description]
	FROM WDQP
	WHERE QueryName = @SourceQuery;
GO
GRANT EXECUTE ON  [dbo].[vspWFCopyNFQuery] TO [public]
GO
