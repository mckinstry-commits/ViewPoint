SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspVPGetFormQuery]
/**************************************************
* Created: CC 8/11/2010
* MODIFIED:	CG 12/03/2010 Issue #140507 - Changed to no longer require column named "KeyID" to indicate identity column			
*			CC 03/24/2011 - Add UniqueAttchID for forms that allow attachments
*		   CJG 04/14/2011 - Fixed SQL generation to handle Computed columns
*			CC 04/26/2011 - Include filters as part of the return set
*		   GPT 07/28/2011 - Alias computer columns that start with dbo.vf correctly.
*		   GPT 08/05/2011 - Only include filters in return set if not included in the DDFI query generation.
*          GPT 08/25/2011 - Modified to select DDFIShared to extract custom fields.  TK-07950 
*		   CJG 04/26/2013 - (TFS 48510) Refactored form query text generation into vspVPGetFormQueryText
*
* This procedure returns the parameters, values, columns, and query text associated with a Grid Query
*
* Inputs:
*	@FormName		The name of the form in DDFH
*	
*
* Output:
*	resultset1	Query Parameters
*	resultset2	Query Columns
*	resultset3	Query Text
*
* Return code:
*
****************************************************/

(@FormName VARCHAR(30))

AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @sql VARCHAR(MAX),
			@keyId VARCHAR(256),
			@formId VARCHAR(256),
			@viewName VARCHAR(256),
			@LineBreak CHAR(2);
			
			
	SELECT	@sql = '',
			@formId =  '''' + @FormName + ''' AS FormName',
			@LineBreak = CHAR(13) + CHAR(10);

	SELECT @viewName = ViewName
	FROM DDFH 
	WHERE Form = @FormName;

	-- Issue 140507- Load the view's identity column (formally always "KeyID") into @keyID
	exec vspDDGetIdentityColumn @viewName, @keyId output;

	-- Include filters as part of the return set, these will be hidden
	-- Only add them if the filter columns are not captured by the previous DDFI selection
	SELECT @sql = @sql + p.ViewName + '.' + p.[ColumnName] + ' , ' + @LineBreak
	FROM VPPartFormChangedMessages m
	INNER JOIN VPPartFormChangedParameters p ON p.FormChangedID = m.KeyID
	LEFT OUTER JOIN dbo.DDFI f ON f.Form = m.FormName AND p.ViewName = f.ViewName AND p.ColumnName = f.ColumnName 
	WHERE FormName = @FormName AND (p.ViewName <> '' AND p.ViewName IS NOT NULL) AND f.ColumnName is Null;

	declare @formSql AS VARCHAR(MAX)
	-- Yes, the keyId is reduntant but for reuse the SP returns it for other uses
	exec vspVPGetFormQueryText @FormName, @sql, @formSql output, @keyId output;

	SELECT @formSql;
	

	SELECT 'FormName' AS Name, -1 AS DefaultOrder, '' AS Datatype, '' AS InputMask, 30 AS InputLength, 0 AS InputType, 0 AS ControlType, 'N' AS ShowGrid, 'FormName' AS ColumnName, 'N' AS IsDescriptionColumn, 'Y'	AS ExcludeFromAggregation
	UNION ALL SELECT 'KEYID' AS Name, -2 AS DefaultOrder, '' AS Datatype, '' AS InputMask, 30 AS InputLength, 0 AS InputType, 0 AS ControlType, 'N' AS ShowGrid, 'KEYID' AS ColumnName, 'N' AS IsDescriptionColumn, 'Y'	AS ExcludeFromAggregation
	UNION ALL SELECT 'UniqueAttchID' AS Name, -3 AS DefaultOrder, '' AS Datatype, '' AS InputMask, 50 AS InputLength, 0 AS InputType, 0 AS ControlType, 'N' AS ShowGrid, 'UniqueAttchID' AS ColumnName, 'N' AS IsDescriptionColumn, 'Y'	AS ExcludeFromAggregation
	UNION ALL
	SELECT	Name,
			ROW_NUMBER() OVER (ORDER BY isnull(GridCol,9999),IsDescriptionColumn) AS DefaultOrder,
			Datatype ,
			InputMask ,
			InputLength,
			InputType,
			ControlType,
			ShowGrid,
			ColumnName,
			IsDescriptionColumn,
			ExcludeFromAggregation
	FROM vfVPGetColumnsForMyViewpoint(@FormName)
	ORDER BY DefaultOrder;

	SELECT	COALESCE(GridColHeading, ColumnName)  AS Name,
			dbo.DDCI.DisplayValue ,
			dbo.DDCI.DatabaseValue
	FROM DDCI
	INNER JOIN DDFI ON dbo.DDCI.ComboType = dbo.DDFI.ComboType
	WHERE Form = @FormName
	AND ControlType <> 99
	AND ColumnName IS NOT NULL;
	
END
GO
GRANT EXECUTE ON  [dbo].[vspVPGetFormQuery] TO [public]
GO
