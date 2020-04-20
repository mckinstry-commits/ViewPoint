SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspVPGetGridQueries]
/**************************************************
* Created: CC 08/15/2008
* Modified: CC 03/05/2009 - Issue #132491 - Return the queries sorted by name
*			CC 04/20/2009 - Issue #133324 - Corrected Security query
*			CC 06/23/2011 - Moved query security to its own UDF to use else where.
*			HH 04/02/2012 - TK-13718 - Added QueryType to selection and create dynamic 
*							query for type view
*			DK 05/30/2012 - TK-15193 - Removed a Trailing AND from the Query
*			HH 05/31/2012 - TK-15193 - added ExcludeFromQuery flag
*			HH 06/13/2012 - TK-15614 - added brackets on column names (for names with spaces)
*			
* This procedure returns the available grid queries and associated columns.
*
* Inputs:
*	@Company
*
* Output:
*	resultset1	Grid Queries
	resultset2	Grid Columns	
*	@errmsg		Error message

*
* Return code:
*	@rcode	0 = success, 1 = failure
*
****************************************************/

(@co bCompany, @Template VARCHAR(20) ,@errmsg VARCHAR(512) OUTPUT)

AS

SET NOCOUNT ON
declare @user bVPUserName
select @user = SUSER_SNAME()

DECLARE @Queries TABLE
(
	QueryName VARCHAR(50),
	QueryID	int,
	QueryTitle VARCHAR(255),
	QueryDescription VARCHAR(512),
	QueryType tinyint,
	Query VARCHAR(MAX)
)

INSERT INTO @Queries
SELECT VPGridQueries.QueryName, VPGridQueries.KeyID, VPGridQueries.QueryTitle, VPGridQueries.QueryDescription, VPGridQueries.QueryType,
		CASE 
			WHEN QueryType = 1 THEN 
			
			'SELECT' + STUFF
			(
				(
					SELECT ', ' + '['+ColumnName+']'
					FROM VPGridColumns C
					WHERE C.QueryName = VPGridQueries.QueryName
							AND C.ExcludeFromQuery = 'N'
					ORDER BY DefaultOrder
					FOR XML PATH('')
				), 1, 1, ''
			) 
			+ ' FROM '
			+ VPGridQueries.Query 
			+ ISNULL(' WHERE ' + STUFF
			(
				(
					SELECT ' ' + ISNULL('['+P.ColumnName+']','') + ' ' + ISNULL(P.Comparison,'') + ' ' + ISNULL(P.ParameterName,'') + ' ' + ISNULL(P.Operator,'')
					FROM VPGridQueryParameters P
					WHERE P.QueryName = VPGridQueries.QueryName
					ORDER BY P.Seq
					FOR XML PATH(''), ROOT('Query'), TYPE 
				).value('/Query[1]','VARCHAR(MAX)'), 1, 1, ''
			), '')
			ELSE 
				VPGridQueries.Query
		END as Query
FROM VPGridQueries
INNER JOIN dbo.vfVPGetQuerySecurity(@user, @co) AS AvailableQueries ON VPGridQueries.QueryName = AvailableQueries.QueryName AND AvailableQueries.Access = 0
INNER JOIN VPGridQueryAssociation ON VPGridQueries.QueryName = VPGridQueryAssociation.QueryName AND VPGridQueryAssociation.TemplateName = @Template AND VPGridQueryAssociation.Active = 'Y'
WHERE VPGridQueries.QueryType<>2

UPDATE @Queries 
SET Query = CASE 
				WHEN (RIGHT(Query,3) IN ('AND', ' OR') AND QueryType = 1 )
					THEN LEFT(Query, LEN(Query)-3)
				ELSE	
					Query
			END 

SELECT * 
FROM @Queries 
ORDER BY QueryName

SELECT * FROM VPGridColumns
INNER JOIN @Queries as Queries ON VPGridColumns.QueryName = Queries.QueryName
WHERE ExcludeFromQuery = 'N'
ORDER BY VPGridColumns.QueryName

GO
GRANT EXECUTE ON  [dbo].[vspVPGetGridQueries] TO [public]
GO
