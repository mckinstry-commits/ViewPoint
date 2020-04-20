SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspUDUpdateAuditTriggers]
/***********************************************************************
*	Created by: 	CC 05/07/2009 - Stored procedure to generate UD audit triggers
*	Checked by:		
* 
*	Altered by: 	
*							
*	Usage:			TableName is the name of the table to create the triggers on,
* 					KeyColumnList is a comma delimited list of columns that reflect the form key value
*					
* 
***********************************************************************/
		@TableName		NVARCHAR(128)	= NULL
	  , @AuditTable		bYN				= 'N'

AS  
BEGIN
	SET NOCOUNT ON;

	DECLARE   @KeyNameList		NVARCHAR(MAX)
			, @KeyColumnList	NVARCHAR(MAX)
			, @IsCompanyBased	bYN
			, @CompanyColumn	NVARCHAR(128)			
			, @bTable			NVARCHAR(128)
			;
	
	SET @bTable = N'b' + @TableName;

	IF OBJECT_ID(@bTable, 'U') IS NULL
		RETURN;
		
	IF @AuditTable = 'N'
		BEGIN
			EXEC dbo.vspHQDropAuditTriggers @bTable;
			RETURN;
		END

	--Generate Key Names and Key Columns lists
	SELECT    @KeyNameList = N''
			, @KeyColumnList = N''
			, @CompanyColumn = NULL
			;
	--Use section symbol to concatinate because the replace of commas in the description 
	--cannot be done in the select statement
	SELECT	  @KeyNameList = @KeyNameList + ISNULL([Description], ColumnName)+ '§'
			, @KeyColumnList = @KeyColumnList + ColumnName + '§'
	FROM UDTC
	WHERE	TableName = @TableName 
			AND KeySeq IS NOT NULL
	ORDER BY DDFISeq
	;
	
	--trim the trailing comma
	SELECT    @KeyNameList = LEFT(@KeyNameList, LEN(@KeyNameList) - 1)
			, @KeyColumnList = LEFT(@KeyColumnList, LEN(@KeyColumnList) - 1)
			;
	
	--clean any commas from the list
	SELECT    @KeyNameList = 	REPLACE(@KeyNameList, ',', '') 
			, @KeyColumnList = 	REPLACE(@KeyColumnList, ',', '') 
			;

	--replace the delimiter
	SELECT    @KeyNameList = 	REPLACE(@KeyNameList, '§', ',') 
			, @KeyColumnList = 	REPLACE(@KeyColumnList, '§', ',') 
			;

	--Check if table is company based
	SELECT @IsCompanyBased = CompanyBasedYN
	FROM UDTH
	WHERE TableName = @TableName
	;
	
	IF ISNULL(@IsCompanyBased, 'N') = 'Y'
		SET @CompanyColumn = 'Co'
		;
		
	--Execute [vspHQCreateAuditTriggers]
	EXEC vspHQCreateAuditTriggers @bTable, @KeyNameList, @KeyColumnList, @CompanyColumn
	;
END


GO
GRANT EXECUTE ON  [dbo].[vspUDUpdateAuditTriggers] TO [public]
GO
