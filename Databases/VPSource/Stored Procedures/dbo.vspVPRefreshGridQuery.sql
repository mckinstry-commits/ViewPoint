SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspVPRefreshGridQuery]
/**************************************************
* Created: CC 10/20/2008
* Modified: CC 10/13/2009 - Issue #132545 Add support for datatypes in grid.
*			HH 04/02/2012 - TK-13718 - Added QueryType in resultset3
*			DK 05/30/2012 - TK-15193 - Removed a Trailing AND from the Query
*			HH 05/31/2012 - TK-15193 - added ExcludeFromQuery flag
*			HH 06/13/2012 - TK-15614 - added brackets on column names (for names with spaces)
*			
* This procedure returns the parameters, values, columns, and query text associated with a Grid Query
*
* Inputs:
*	@QueryName		The name of the query
*	@QueryID		The KeyID of the query
*
* Output:
*	resultset1	Query Parameters
*	resultset2	Query Columns
*	resultset3	Query Text
*
* Return code:
*
****************************************************/

(@QueryName VARCHAR(50), @QueryID INT)

AS

SET NOCOUNT ON

SELECT 	Parameters.KeyID, 
		Parameters.QueryName, 
		Parameters.ParameterName, 
		Parameters.[Value], 
		Parameters.IsVisible, 
		Parameters.[Description], 
		COALESCE(Parameters.InputType, DataTypes.InputType) AS 'InputType', 
		COALESCE(Parameters.InputLength, DataTypes.InputLength) AS 'InputLength', 
		COALESCE(Parameters.Prec, DataTypes.Prec) AS 'Prec'
FROM VPGridQueryParameters AS Parameters
INNER JOIN VPGridQueries AS Q ON Parameters.QueryName = Q.QueryName AND Q.KeyID = @QueryID
LEFT OUTER JOIN DDDTShared DataTypes ON Parameters.DataType = DataTypes.Datatype;


SELECT C.QueryName ,
        C.ColumnName AS Name,
        C.VisibleOnGrid AS IsVisible,
        C.IsStandard ,
        C.Datatype ,
        DDDTShared.InputLength, 
        DDDTShared.InputMask,
        C.ExcludeFromAggregation ,
        C.DefaultOrder
FROM VPGridColumns AS C
INNER JOIN VPGridQueries AS Q ON C.QueryName = Q.QueryName AND Q.KeyID = @QueryID
LEFT OUTER JOIN dbo.DDDTShared ON C.Datatype = DDDTShared.Datatype
WHERE C.ExcludeFromQuery = 'N';



DECLARE @Queries TABLE(	Query VARCHAR(MAX),
						QueryTitle VARCHAR(255),
						QueryType tinyint) 

INSERT INTO @Queries(Query, QueryTitle, QueryType)
SELECT
		CASE 
			WHEN QueryType = 1 THEN 
			
			'SELECT' + STUFF
			(
				(
					SELECT ', ' + '['+ColumnName+']'
					FROM VPGridColumns C
					WHERE C.QueryName = Q.QueryName
							AND C.ExcludeFromQuery = 'N'
					ORDER BY DefaultOrder
					FOR XML PATH('')
				), 1, 1, ''
			) 
			+ ' FROM '
			+ Q.Query 
			+ ISNULL(' WHERE ' + STUFF
			(
				(
					SELECT ' ' + ISNULL('['+P.ColumnName+']','') + ' ' + ISNULL(P.Comparison,'') + ' ' + ISNULL(P.ParameterName,'') + ' ' + ISNULL(P.Operator,'')
					FROM VPGridQueryParameters P
					WHERE P.QueryName = Q.QueryName
					ORDER BY P.Seq
					FOR XML PATH(''), ROOT('Query'), TYPE 
				).value('/Query[1]','VARCHAR(MAX)'), 1, 1, ''
			), '')
			ELSE 
				Q.Query
		END as Query,
		Q.QueryTitle, QueryType 
FROM	VPGridQueries Q
WHERE	QueryName = @QueryName;

UPDATE @Queries 
SET Query = CASE 
				WHEN (RIGHT(Query,3) IN ('AND', ' OR') AND QueryType = 1 )
					THEN LEFT(Query, LEN(Query)-3)
				ELSE	
					Query
			END 

SELECT * FROM @Queries
GO
GRANT EXECUTE ON  [dbo].[vspVPRefreshGridQuery] TO [public]
GO
