SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**************************************************
* Created: CJG 3/11/11
* MODIFIED:	CJG 3/23/11 - D-01485 - Moved filter generation to code (except KeyID)
*			HH 8/18/11 - TK-07851 - Added ISNULL check on JoinClause
*			JG 8/19/11 - TK-00000 - Fixed a small defect for computed columns
*			GPT 10/26/2011 - TK-09448 - Added additional tweaks for computed columns and only return the first record.
*           
*			
* This procedure executes the Grid Query for the given form
*
* Inputs:
*	@FormName		The name of the form in DDFH
*	
*
* Output:
*	form query results
*
* Return code:
*
****************************************************/
CREATE PROCEDURE [dbo].[vspVPGetFilteredFormQuery] 
	@FormName VARCHAR(30)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    DECLARE @sql VARCHAR(MAX),
			@keyId VARCHAR(256),
			@formId VARCHAR(256),
			@viewName VARCHAR(256);
			
	SELECT	@sql = '',
			@formId =  '''' + @FormName + ''' AS FormName';

	SELECT @viewName = ViewName
	FROM DDFHShared
	WHERE Form = @FormName;

	-- Issue 140507- Load the view's identity column (formally always "KeyID") into @keyID
	exec vspDDGetIdentityColumn @viewName, @keyId output;

	SELECT @sql = @sql + CASE -- Must handle computed columns that may be formatted like "(col1 + col2)" and also handle DDFI entries that are marked Computed but are a single column and need "View." added
							WHEN ViewName IS NOT NULL AND (Computed = 'N' OR NOT [ColumnName] LIKE '% %')
								THEN ViewName + '.' + [ColumnName]
							WHEN Computed = 'Y' AND ( LEFT([ColumnName],2) = 'vf' OR LEFT([ColumnName],6) = 'dbo.vf' )
								THEN + CASE WHEN LEFT([ColumnName],4) <> 'dbo.' THEN 'dbo.' ELSE '' END + ISNULL([ColumnName],'') +' AS ' + QUOTENAME(ISNULL(GridColHeading, ''))
							WHEN Computed = 'Y' AND [ColumnName] LIKE '% %' OR GridColHeading is Not Null
								THEN [ColumnName] + ' AS ' +  QUOTENAME(REPLACE(REPLACE(COALESCE(GridColHeading, ColumnName), '[', '' ), ']', ''))
							ELSE [ColumnName] 
						 END 
						 + ISNULL(' , ' + DescriptionColumn, '') + ' , '
	FROM DDFIShared
	WHERE Form = @FormName	
	AND ColumnName IS NOT NULL
	AND ( ControlType <> 5 OR ShowGrid = 'Y') ;	

	SET @sql = @sql + @viewName + '.UniqueAttchID, '

	SELECT @sql = 'SELECT TOP 1 ' + @sql + @formId + ' , ' + QUOTENAME(ViewName) + '.' + QUOTENAME(@keyId) + ' AS KEYID FROM ' + ViewName + ' ' + ISNULL(JoinClause, '')
	FROM DDFHShared
	WHERE Form = @FormName;
	
	
	
	-- Always filter on KeyID
	SET @sql = @sql + ' WHERE ' + QUOTENAME(@viewName) + '.' + QUOTENAME(@keyId) + ' = @KEYID'

	-- Code will add any additional filter parameters
	
	SELECT @sql;
	
END

GO
GRANT EXECUTE ON  [dbo].[vspVPGetFilteredFormQuery] TO [public]
GO
