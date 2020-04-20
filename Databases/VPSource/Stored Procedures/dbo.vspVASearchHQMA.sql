SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspVASearchHQMA]
/***********************************************************************
*	Created by: 	CC 05/28/2009 - Stored procedure to search HQMA
*	Checked by:		
* 
*	Altered by: 	
*							
*	Usage:			TableName is the name of the table to create the triggers on,
* 					KeyColumnList is a comma delimited list of columns that reflect the form key value
*					
* 
***********************************************************************/
		@CompanyFilter			bCompany	 = NULL
	  , @TableFilter			VARCHAR(128) = NULL
	  , @FieldFilter			VARCHAR(128) = NULL
	  , @UserFilter				VARCHAR(128) = NULL
	  , @MaxNumberOfRecords		int			 = NULL

AS  
BEGIN

DECLARE   @SearchQuery		NVARCHAR(MAX)                              
        , @ParameterList	NVARCHAR(MAX)
        , @OrderByClause	NVARCHAR(26)
        , @TopFilter		NVARCHAR(100)
        ;

IF @MaxNumberOfRecords IS NOT NULL
	SET @TopFilter = N' TOP(@xMaxRecords) ';
ELSE
	SET @TopFilter = N'';
                                                 
SELECT @SearchQuery =                                                      
    N'SELECT	' +  @TopFilter + '  TableName
				, KeyString
				, Co
				, RecType
				, FieldName
				, OldValue
				, NewValue
				, [DateTime]
				, UserName
     FROM   dbo.HQMA AS AuditLog
     WHERE  1 = 1 '
     , @OrderByClause = N' ORDER BY [DateTime] DESC '
	 , @ParameterList =
	'   @xCo			bCompany
	  , @xTableName		VARCHAR(128)
	  , @xFieldName		VARCHAR(128)
	  , @xUserName		VARCHAR(128)
	  , @xMaxRecords	int'
	  ;
     
IF @CompanyFilter IS NOT NULL
	SELECT @SearchQuery = @SearchQuery + ' AND AuditLog.Co = @xCo ';

IF @TableFilter IS NOT NULL
	IF CHARINDEX('%', @TableFilter) = 0
		SELECT @SearchQuery = @SearchQuery + ' AND AuditLog.TableName = @xTableName ';
	ELSE
		SELECT @SearchQuery = @SearchQuery + ' AND AuditLog.TableName LIKE @xTableName ';

IF @FieldFilter IS NOT NULL
	IF CHARINDEX('%', @FieldFilter) = 0
		SELECT @SearchQuery = @SearchQuery + ' AND AuditLog.FieldName = @xFieldName ';
	ELSE
		SELECT @SearchQuery = @SearchQuery + ' AND AuditLog.FieldName LIKE @xFieldName ';

IF @UserFilter IS NOT NULL
	IF CHARINDEX('%', @UserFilter) = 0
		SELECT @SearchQuery = @SearchQuery + ' AND AuditLog.UserName = @xUserName ';
	ELSE
		SELECT @SearchQuery = @SearchQuery + ' AND AuditLog.UserName LIKE @xUserName ';

SELECT @SearchQuery =  @SearchQuery + @OrderByClause;
                                                                   
EXEC sp_executesql	  @SearchQuery
					, @ParameterList
					, @CompanyFilter
					, @TableFilter
					, @FieldFilter
					, @UserFilter
					, @MaxNumberOfRecords
					;
END


GO
GRANT EXECUTE ON  [dbo].[vspVASearchHQMA] TO [public]
GO
