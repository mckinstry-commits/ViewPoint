SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE            PROC [dbo].[vspPMCreateDocMergeInfo]
   /***********************************************************
    * CREATED BY: AJW 11/20/2012
    * MODIFIED By : 
    *				GPT 11/30/2012 Returns zero based word table. Reviewed by Andy W.
	*				AJW 7/9/13 TFS 55289 - Order by distribution Seq to ensure records return in same order as Create and Send form
	*				AJW 12/3/13 TFS 68582 - Unable to create POCO documents
	*				AJW 12/10/13 TFS 67486 - bPct * 100 to match output of bspHQWFMergeFieldBuild.
	*				
    * USAGE:  Returns the dataset used by Create AND SEND for a word template
    * 
    *
    * INPUT PARAMETERS
    *   TemplateType
	*   DocObject
	*   SourceView
	*   SourceKeyID
	*   customMergeColumns - used for adding any additional columns caller wants added to merge output
	*          Expected Format ColumnName1=Value1,ColumnName2=Value2
	*   customMergeJoin - used to join to additional tables in the merge query
	*	   Expected format/example
	*     'left join PMOPTotals with (nolock) on'+
    *     ' PMOPTotals.PMCo=a.PMCo and PMOPTotals.Project=a.Project and'+
    *     ' PMOPTotals.PCOType=a.PCOType and PMOPTotals.PCO=a.PCO' 
	*   customWhereClause - used for adding additional where clause parameter in merge query
	*      Expected format/example 'a.Send = ''Y'' and a.CC = ''N'' '
	*   optionalWordTableJoin - used for adding a custom JOIN to the word table merge 
	*          Expected Use IS to JOIN back to the KeyID table
	*   optionalWordTableKeyIdAlias - used to specify which JOIN table alias contains the keyid
	*          Expected Value the same table alias used in the word table JOIN
    *   
    * OUTPUT PARAMETERS
    *   @errmsg        error message if something went wrong
    * RETURN VALUE
    *   0 Success
    *   1 fail
    ************************************************************************/
    (
	  @Company bCompany,
      @templatename bReportTitle,
	  @templatetype VARCHAR(10),
	  @viewname VARCHAR(30),
	  @keyid bigint,
	  @customMergeColumns VARCHAR(MAX) = NULL,
	  @customMergeJoin VARCHAR(MAX) = NULL,
	  @customWhereClause VARCHAR(MAX) = NULL,
	  @optionalWordTableJoin VARCHAR(MAX) = NULL,
	  @optionalWordTableKeyIdAlias VARCHAR(MAX) = NULL,
	  @optionalWordTableWhereClause VARCHAR(MAX) = NULL,
      @errmsg VARCHAR(500) OUTPUT
    )
AS 
SET NOCOUNT ON
BEGIN
    DECLARE @ERRSUFFIX VARCHAR(MAX), @sqlWordTableMergeTable VARCHAR(MAX),
	        @JoinClauseWordTable VARCHAR(MAX),@whereWordTableClauseAlias VARCHAR(MAX),
			@docWordTableColumnList VARCHAR(MAX), @docWordTableColumnListOrderBy VARCHAR(MAX),
			@sqlMergeTable VARCHAR(MAX),
			@nsqlStatement NVARCHAR(MAX),
			@JoinClause VARCHAR(MAX), @JoinOrder int,@WhereClauseAlias VARCHAR(MAX),
			@docColumnList VARCHAR(MAX), 
			@noAliasColumnList VARCHAR(MAX), 
			@distributionTable VARCHAR(MAX),
			@distributionAlias VARCHAR(MAX),
			@distributionSeqColumn VARCHAR(MAX),
			@mergeOrder INT, @dateformat VARCHAR(MAX),
			@tmpTableName VARCHAR(MAX),
			@params nvarchar(500)


	SET @ERRSUFFIX = dbo.vfToString(@templatename) + ' - '  + OBJECT_NAME(@@PROCID)
	-- create a unique temp table name
	select @tmpTableName = dbo.vfStripNonAlphaNumerics(SUSER_NAME()) + '_' + REPLACE(NEWID(),'-','')
    -- check params
	IF @Company IS NULL
	BEGIN
	  SELECT @errmsg = 'Company param can not be NULL' + @ERRSUFFIX
	  RETURN 1
	END
	IF @templatename IS NULL
	BEGIN
	  SELECT @errmsg = 'Template Name param can not be NULL' + @ERRSUFFIX
	  RETURN 1
	END

	IF @templatetype IS NULL
	BEGIN
	  SELECT @errmsg = 'Template Type param can not be NULL' + @ERRSUFFIX
	  RETURN 1
	END

	-- convert POCO to PURCHASECO if needed
	IF @templatetype = 'POCO' set @templatetype = 'PURCHASECO'


	IF @viewname IS NULL
	BEGIN
	  SELECT @errmsg = 'View Name param can not be NULL' + @ERRSUFFIX
	  RETURN 1
	END

	-- convert SLHDPM & POHDPM to SLHD & POHD because HQWO is setup for SLHD & POHD
	if (@viewname in ('SLHDPM','POHDPM')) select @viewname = replace(@viewname,'PM','')

	IF @keyid IS NULL
	BEGIN
	  SELECT @errmsg = 'Key Id param can not be NULL' + @ERRSUFFIX
	  RETURN 1
	END

	-- get date format support MM/DD/YYYY DD/MM/YYYY
	SELECT @dateformat = CASE ReportDateFormat
		WHEN 2 THEN '103' 
		WHEN 3 THEN '111'
		ELSE '101' END
	FROM HQCO WHERE HQCo = @Company

	-- Set distribution table DocCategory/TemplateType or set to empty string
	SELECT TOP 1 @distributionTable=DistributionTable FROM PMDocDistribution WHERE DocCat = @templatetype
	SET @distributionTable = dbo.vfToString(@distributionTable)
	--Set distribution table alias from HQWO if applicable
	SELECT TOP 1 @distributionAlias = Alias FROM HQWO WHERE TemplateType = @templatetype AND ObjectTable = @distributionTable
	SET @distributionAlias = dbo.vfToString(@distributionAlias)

	--Set distribution Seq column name
	SELECT @distributionSeqColumn = case @templatetype
		WHEN 'RFQ' THEN 'RFQSeq'
		WHEN 'RFI' THEN 'RFISeq'
		ELSE 'Seq'	END

	-- build Merge Column list

	SET @docColumnList = ''
	SET @noAliasColumnList = ''

	SELECT  @noAliasColumnList = @noAliasColumnList +
			CASE @noAliasColumnList WHEN '' THEN '' ELSE ', ' END + f.MergeFieldName,
			@docColumnList=@docColumnList + 
	        CASE @docColumnList WHEN '' THEN '' ELSE ', ' END + 
			--check for bDate type
			case when t.name = 'bDate' then 
			'convert(varchar,'+o.Alias+'.'+f.ColumnName+',' + @dateformat +')' 
			when t.name = 'bPct' then
			'dbo.vfToString(isnull(' + o.Alias+'.'+f.ColumnName + ',0) * 100)'
			else
			o.Alias+'.'+f.ColumnName 
			end + ' as ['+f.MergeFieldName+']' + CHAR(13)
	FROM dbo.HQWD d
	JOIN dbo.HQWF f on d.TemplateName=f.TemplateName
	JOIN dbo.HQWO o on d.TemplateType=o.TemplateType AND o.DocObject=f.DocObject
	JOIN sysobjects j on j.name = o.ObjectTable
	JOIN syscolumns c on c.name=f.ColumnName and c.id=j.id
	JOIN systypes t on c.usertype=t.usertype
  	WHERE d.TemplateName=@templatename AND d.TemplateType=@templatetype AND f.WordTableYN='N'
	order by o.JoinOrder

	-- add any custom columns specified
	IF @customMergeColumns IS NOT NULL
	BEGIN
		set @docColumnList = @docColumnList + CASE WHEN LEFT(@customMergeColumns,1) <> ',' THEN ',' + @customMergeColumns 
				ELSE @customMergeColumns END
	END

	--build JOIN clause for query

	set @JoinClause = ''
	set @WhereClauseAlias = ''
	set @JoinOrder = 0

	SELECT  @JoinClause = @JoinClause + 
	        CASE @JoinClause WHEN '' THEN '' ELSE 
			CASE WHEN o.Required = 'Y' THEN ' JOIN ' ELSE ' LEFT JOIN ' END 
			END +
			o.ObjectTable + ' ' + o.Alias + ' ' +
			CASE WHEN o.JoinClause IS NULL THEN '' ELSE ' on ' + o.JoinClause END +CHAR(13),
			@WhereClauseAlias = @WhereClauseAlias + CASE WHEN o.ObjectTable = @viewname THEN o.Alias ELSE '' END,
			@JoinOrder=o.JoinOrder
	FROM dbo.HQWD d
	JOIN dbo.HQWO o on d.TemplateType=o.TemplateType
	WHERE d.TemplateName=@templatename AND d.TemplateType=@templatetype AND o.WordTable='N'
	order by o.JoinOrder



	--verify we have all the params we need for merge query
	IF dbo.vfToString(@docColumnList) = '' OR
	   dbo.vfToString(@JoinClause) = '' OR
	   dbo.vfToString(@WhereClauseAlias) = ''
	BEGIN
	  SET @errmsg = 'Unable to determine correct merge query string for template ' + @ERRSUFFIX
	  RETURN 1
	END

	-- columns
	SET @sqlMergeTable = 'SELECT DISTINCT '+ @docColumnList + CHAR(13) +
		CASE WHEN dbo.vfToString(@distributionAlias) = '' THEN '' ELSE
		','+@distributionAlias + '.' + @distributionSeqColumn
		END + CHAR(13)

	-- temp table
	SET @sqlMergeTable = @sqlMergeTable +
		'INTO ##' + @tmpTableName + CHAR(13) +
		'FROM ' + @JoinClause + CHAR(13) 


	---- custom join
	SET @sqlMergeTable = @sqlMergeTable +
	   	-- set optional join for merge query
		CASE WHEN dbo.vfToString(@customMergeJoin) = '' THEN '' ELSE @customMergeJoin END + CHAR(13) 


	-- where clause
	SET @sqlMergeTable = @sqlMergeTable +
	   'WHERE ' + @WhereClauseAlias + '.KeyID=' + dbo.vfToString(@keyid) + CHAR(13) +
	   CASE WHEN @customWhereClause is not null THEN ' AND ' + @customWhereClause + ' ' ELSE '' END +
	   CASE WHEN dbo.vfToString(@distributionAlias) = '' THEN '' ELSE
		-- filter out old PMSS records we set to Seq -1
	   ' AND ' + @distributionAlias + '.' + @distributionSeqColumn + ' <> -1 ORDER BY ' + @distributionAlias + '.' + @distributionSeqColumn
	   END



    BEGIN TRY
		--populate temp table with query results
	    print @sqlMergeTable
		--sp_executesql has a 4K nvarchar limit so use exec
		EXEC(@sqlMergeTable)

		--check to see if one or more rows should be returned
		DECLARE @rowcnt int;	

		SET @params = N'@rowCntOut int OUTPUT'
		SET @rowcnt = 0;
		SET @nsqlStatement = 'select @rowCntOut=count(1) from' + CHAR(13) +
		'(SELECT DISTINCT ' + @noAliasColumnList + CHAR(13) +
		'FROM ##' + @tmpTableName + CHAR(13) +
		')a'


		print @nsqlStatement
		EXECUTE sp_executesql @nsqlStatement, @params, @rowCntOut=@rowcnt OUTPUT;

		IF @rowcnt = 1
		BEGIN
			SET @nsqlStatement = 'SELECT DISTINCT TOP 1 * ' + CHAR(13) +
			'FROM ##' + @tmpTableName + CHAR(13)	
		END
		ELSE
		BEGIN
			SET @nsqlStatement = 'SELECT * ' + CHAR(13) +
			'FROM ##' + @tmpTableName + CHAR(13) +
			CASE WHEN dbo.vfToString(@distributionAlias) = '' THEN '' ELSE
				'ORDER BY ' + @distributionSeqColumn
			END	
		END
		
		SET @nsqlStatement = @nsqlStatement + CHAR(13) +
		'drop table ##' + @tmpTableName + CHAR(13)
		print @nsqlStatement
		EXEC (@nsqlStatement)

	END TRY
	BEGIN CATCH
		SET @errmsg='Unable to retrieve record for template ' + @ERRSUFFIX
		SELECT ERROR_NUMBER() AS ErrorNumber,
			ERROR_SEVERITY() AS ErrorSeverity,
			ERROR_STATE() as ErrorState,
			ERROR_PROCEDURE() as ErrorProcedure,
			ERROR_LINE() as ErrorLine,
			ERROR_MESSAGE() as ErrorMessage
		BEGIN TRY
			SET @nsqlStatement = 'if OBJECT_ID(##'+@tmpTableName+') IS NOT NULL DROP TABLE ##'+@tmpTableName
			EXEC (@nsqlStatement)
		END TRY
		BEGIN CATCH
			SELECT ERROR_NUMBER() AS ErrorNumber,
				ERROR_SEVERITY() AS ErrorSeverity,
				ERROR_STATE() as ErrorState,
				ERROR_PROCEDURE() as ErrorProcedure,
				ERROR_LINE() as ErrorLine,
				ERROR_MESSAGE() as ErrorMessage
			RETURN 1
		END CATCH
		RETURN 1	
	END CATCH
	

	--if empty dataset or no word table required
	IF NOT EXISTS(SELECT 1 FROM HQWF WHERE TemplateName=@templatename and WordTableYN='Y')
	BEGIN
		RETURN 0
	END


	--build Word Table Merge Column List

	SET @docWordTableColumnList = ''
	SET @docWordTableColumnListOrderBy = ''
	SET @mergeOrder=0

	SELECT  @docWordTableColumnListOrderBy= @docWordTableColumnListOrderBy +
	        CASE @docWordTableColumnListOrderBy WHEN '' THEN '' ELSE ', ' END +
			'['+f.MergeFieldName+']',
			@docWordTableColumnList=@docWordTableColumnList + 
	        CASE @docWordTableColumnList WHEN '' THEN '' ELSE ', ' END +
			CASE WHEN CHARINDEX('+',f.ColumnName)<>0
			THEN
			   -- This block only supports the following string format "column1 + ' _ ' + column2"
			   -- alias for the First column
			   'dbo.vfToString(' + o.Alias + '.' + ltrim(substring(f.ColumnName,1,CHARINDEX('+',f.ColumnName)-1)) + ') ' +
			   -- put the delimeter 
			   substring(f.ColumnName,CHARINDEX('+',f.ColumnName),CHARINDEX('+',f.ColumnName,CHARINDEX('+',f.ColumnName)+1 ) - CHARINDEX('+',f.ColumnName) + 1 ) +
			   --alias for the second column
			   ' dbo.vfToString(' + o.Alias + '.' + ltrim(
			   substring(f.ColumnName,  CHARINDEX('+',f.ColumnName,CHARINDEX('+',f.ColumnName)+1 )+1 , 
			   len(f.ColumnName) - 
			   CHARINDEX('+',f.ColumnName,CHARINDEX('+',f.ColumnName)+1)+1) ) + ')'
			ELSE
				 --check for bDate type
				case when isnull(t.name,'') = 'bDate' then 
				'convert(varchar,'+o.Alias+'.'+f.ColumnName+',101)' 
				else
				o.Alias+'.'+f.ColumnName 
				end
			END + ' as ['+f.MergeFieldName+']',
			@mergeOrder=f.MergeOrder
	FROM dbo.HQWD d
	JOIN dbo.HQWF f on d.TemplateName=f.TemplateName
	JOIN dbo.HQWO o ON d.TemplateType=o.TemplateType AND o.DocObject=f.DocObject
	JOIN sysobjects j on j.name = o.ObjectTable
	LEFT JOIN syscolumns c on c.name=f.ColumnName and c.id=j.id
	LEFT JOIN systypes t on c.usertype=t.usertype
	WHERE d.TemplateName=@templatename AND d.TemplateType=@templatetype AND f.WordTableYN='Y'
	ORDER BY f.MergeOrder

	--build JOIN clause for word table query
	
	SET @JoinClauseWordTable = ''
	SET @whereWordTableClauseAlias = ''
	SET @JoinOrder = 0

	SELECT  @JoinClauseWordTable = @JoinClauseWordTable + 
	        CASE @JoinClauseWordTable WHEN '' THEN '' ELSE 
			CASE WHEN o.Required = 'Y' THEN ' JOIN ' ELSE ' LEFT JOIN ' END 
			END +
			o.ObjectTable + ' ' + o.Alias + ' ' +
			CASE WHEN o.JoinClause IS NULL THEN '' ELSE ' on ' + o.JoinClause END +CHAR(13),
			@whereWordTableClauseAlias = @whereWordTableClauseAlias + CASE WHEN o.ObjectTable = @viewname THEN o.Alias ELSE '' END,
			@JoinOrder=o.JoinOrder
	FROM dbo.HQWD d
	JOIN dbo.HQWO o ON d.TemplateType=o.TemplateType
	WHERE d.TemplateName=@templatename AND d.TemplateType=@templatetype AND o.WordTable='Y'
	ORDER BY o.JoinOrder

	-- set custom word table merge AND ensure we know the keyid table alias
	IF @optionalWordTableJoin IS NOT NULL
	BEGIN
	  SET @JoinClauseWordTable = @JoinClauseWordTable + CASE WHEN LEFT(@optionalWordTableJoin,1) <> ' ' THEN ' '+@optionalWordTableJoin ELSE @optionalWordTableJoin END+CHAR(13)
	END

	IF @optionalWordTableKeyIdAlias IS NOT NULL
	BEGIN
	  SET @whereWordTableClauseAlias = @optionalWordTableKeyIdAlias
	END

	-- select  dbo.vfToString(@docWordTableColumnList),  dbo.vfToString(@docWordTableColumnListOrderBy),
	-- dbo.vfToString(@JoinClauseWordTable),dbo.vfToString(@whereWordTableClauseAlias)

	--verify we have all the params we need for merge query
	IF dbo.vfToString(@docWordTableColumnList) = '' OR
	   dbo.vfToString(@docWordTableColumnListOrderBy) = '' OR
	   dbo.vfToString(@JoinClauseWordTable) = '' OR
	   dbo.vfToString(@whereWordTableClauseAlias) = ''
	BEGIN

	  print '
	  '+dbo.vfToString(@docWordTableColumnList) + ',
	  '+dbo.vfToString(@docWordTableColumnListOrderBy)+ ',
	  '+dbo.vfToString(@JoinClauseWordTable)+ ',
	  '+dbo.vfToString(@whereWordTableClauseAlias)

	  SET @errmsg = 'Unable to determine correct word table merge query string for template ' + @ERRSUFFIX
	  RETURN 1
	END
	
	--Return Word Table Result Set *NOTE THE SPECIAL CASE FOR SUBITEM

	SET @sqlWordTableMergeTable = 'SELECT DISTINCT '+ @docWordTableColumnList + CHAR(13) +
	   'FROM ' + @JoinClauseWordTable + CHAR(13) +
	   'WHERE ' + @whereWordTableClauseAlias + '.KeyID=' + dbo.vfToString(@keyid) + CHAR(13) +
	   CASE WHEN @optionalWordTableWhereClause is not null THEN ' AND ' + @optionalWordTableWhereClause + ' ' ELSE '' END + CHAR(13) +
	   CASE WHEN @templatetype = 'SUBITEM' THEN
		   ' and a.SendFlag = ''Y'' and not exists(select * from SLIT c with (nolock) where c.SLCo=a.SLCo and c.SL=a.SL and c.SLItem=a.SLItem)	
		   UNION' + CHAR(13) +
		   'SELECT DISTINCT '+
		   dbo.vfPMSLtoSLIT(@docWordTableColumnList) + CHAR(13) +
		   'FROM ' + dbo.vfPMSLtoSLIT(@JoinClauseWordTable) + CHAR(13) +
		   'WHERE ' + @whereWordTableClauseAlias + '.KeyID=' + dbo.vfToString(@keyid) + CHAR(13) +
		   CASE WHEN @optionalWordTableWhereClause is not null THEN ' AND ' + dbo.vfPMSLtoSLIT(@optionalWordTableWhereClause) + ' ' ELSE '' END 
	   ELSE '' END +
	   'ORDER BY ' + @docWordTableColumnListOrderBy

	BEGIN TRY
	    print '
		WordTableQuery:
		'+@sqlWordTableMergeTable

		EXEC (@sqlWordTableMergeTable)
	END TRY
	BEGIN CATCH
		SET @errmsg='Unable to retrieve word table records for template ' + @ERRSUFFIX
		RETURN 1	
	END CATCH

	-- Return Word Table Index as 3rd dataset
	-- Merge expects zero base indexing
	select CAST((WordTable - 1) as TinyInt) as WordTable 
	from HQWD where TemplateName = @templatename

	RETURN 0

END

GO
GRANT EXECUTE ON  [dbo].[vspPMCreateDocMergeInfo] TO [public]
GO
