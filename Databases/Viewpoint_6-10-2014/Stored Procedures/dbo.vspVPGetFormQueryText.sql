SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspVPGetFormQueryText]
/**************************************************
* Created: Chris G 4/26/2013
*
* This procedure returns the query text for a form.
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

(@FormName VARCHAR(30), @AdditionalColumns AS VARCHAR(MAX), @formSql AS VARCHAR(MAX) OUTPUT, @keyId VARCHAR(256) OUTPUT)

AS
BEGIN
	DECLARE @sql VARCHAR(MAX),
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

	SELECT @sql = @sql + CASE -- Must handle computed columns that may be formatted like "(col1 + col2)" and also handle DDFI entries that are marked Computed but are a single column and need "View." added
							WHEN ViewName IS NOT NULL AND (Computed = 'N' OR NOT [ColumnName] LIKE '% %')
								THEN ViewName + '.' + [ColumnName]
							WHEN Computed = 'Y' AND ( LEFT([ColumnName],2) = 'vf' OR LEFT([ColumnName],6) = 'dbo.vf' )
								THEN + CASE WHEN LEFT([ColumnName],4) <> 'dbo.' THEN 'dbo.' ELSE '' END + ISNULL([ColumnName],'') +' AS ' + QUOTENAME(ISNULL(GridColHeading, ''))
							WHEN Computed = 'Y' AND [ColumnName] LIKE '% %' OR GridColHeading is Not Null
								THEN [ColumnName] + ' AS ' +  QUOTENAME(REPLACE(REPLACE(COALESCE(GridColHeading, ColumnName), '[', '' ), ']', ''))
							ELSE [ColumnName] 
						 END 
						 + ISNULL(' , ' + DescriptionColumn, '') + ' , ' + @LineBreak
	FROM dbo.vfDDFIShared(@FormName)
	WHERE Form = @FormName	
	AND ColumnName IS NOT NULL
	AND ( ControlType <> 5 OR ShowGrid = 'Y' ) ;	

	IF @AdditionalColumns IS NOT NULL
		BEGIN
			SELECT @sql = @sql + @AdditionalColumns
		END
		
	SELECT @sql = 'SELECT ' + @sql + 
									CASE 
										WHEN AllowAttachments = 'Y' THEN QUOTENAME(ViewName)+'.UniqueAttchID , ' + @LineBreak
										ELSE ''
									END
					+ @formId + ' , ' + QUOTENAME(ViewName) + '.' + QUOTENAME(@keyId) + ' AS KEYID FROM ' + ViewName + ' ' + ISNULL(JoinClause, '')
	FROM DDFH 
	WHERE Form = @FormName;

	SET @keyId = QUOTENAME(@viewName) + '.' + QUOTENAME(@keyId)
	SET @formSql = @sql;
END
GO
GRANT EXECUTE ON  [dbo].[vspVPGetFormQueryText] TO [public]
GO
