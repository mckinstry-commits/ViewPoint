SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*************************************/
CREATE Proc [dbo].[vspPMRecordRelateKeyWordSearch]
/*******************************
* Created By:	GF 11/06/2010 - issue #141957
* Modified By:	GF 03/29/2011 TK-03298 TK-03298 TK-03569
*				GF 06/21/2011 D-02339
*
* This stored procedurew will be used to 
* search all columns of all tables for a module
* for a given search string and return a list
* of table columns and results.
*
* Currently on text will be search. Not case sensitive.
*
* The global temp table ##SearchResults is created in the calling procedure.
*
* input paramters
* @SearchStr	Key word to search for
*
*******************************/
(@SearchStr nvarchar(100), @TypeOfSearch NCHAR(1) = 'G', @ReportStyle NVARCHAR(10) = '101')
as
set nocount on

DECLARE @rcode INT, @TableName NVARCHAR(256), @ColumnName NVARCHAR(256),
		@TextStr NVARCHAR(110), @KeyID NVARCHAR(10),
		@Number NVARCHAR(128), @Name NVARCHAR(128), @VendorSearch NVARCHAR(50),
		@VendorGroup NVARCHAR(128), @ParamsDef nvarchar(max), @Query nvarchar(max)

SET @rcode = 0

SET @SearchStr = REPLACE(@SearchStr,'%', '_')
SET @TextStr = LOWER(QUOTENAME('%' + @SearchStr + '%',''''))

SET @KeyID = 'KeyID'

--IF OBJECT_ID('tempdb..##SearchResults') IS NOT NULL
--	BEGIN
--	DROP TABLE ##SearchResults
--	END
	
---- verify ##SearchResults temp table exists
If Object_Id('tempdb..##SearchResults') IS NULL
	BEGIN
	CREATE TABLE ##SearchResults
	(
	TableName NVARCHAR(128),
	ColumnName NVARCHAR(128),
	ColumnValue NVARCHAR(400),
	KeyID NVARCHAR(10)
	)
	END

---- drop table fir vendor/firm
IF OBJECT_ID('tempdb..#VendorColumns') IS NOT NULL
	BEGIN
	DROP TABLE #VendorColumns
	END

---- create table for vendor/firm matching search records
IF OBJECT_ID('tempdb..#VendorColumns') IS NULL
	BEGIN
	CREATE TABLE #VendorColumns
	(
		TableName	NVARCHAR(128),
		VendorGroup	NVARCHAR(128),
		Number		NVARCHAR(128),
		Name		NVARCHAR(128),
		VendorID	NVARCHAR(128)
	)
	END

SET @VendorSearch = '#VendorColumns'


---- create table and columns to search
DECLARE @PMTableColumns TABLE
(
	TableName	NVARCHAR(128),
	ColumnName	NVARCHAR(128)
)

---- we need to get the tables to search based on the forms we are
---- allowing record relating too.
---- create table to store the table names that we will be searching on
DECLARE @TablesToSearch TABLE
(
	TableName	NVARCHAR(128)
)

---- populate table from function
insert into @TablesToSearch SELECT * FROM dbo.vfPMTablesToSearch ('G')



---- populate with Table Range - depends on the type of search
IF ISNULL(@TypeOfSearch,'') <> 'V'
	BEGIN
	INSERT INTO @PMTableColumns (TableName, ColumnName)
	SELECT c.TABLE_SCHEMA + '.' + c.TABLE_NAME, c.COLUMN_NAME
	FROM INFORMATION_SCHEMA.COLUMNS c
	INNER JOIN INFORMATION_SCHEMA.TABLES t ON t.TABLE_SCHEMA=c.TABLE_SCHEMA AND t.TABLE_NAME=c.TABLE_NAME
	INNER JOIN sys.types s ON s.name=c.DATA_TYPE
	INNER JOIN @TablesToSearch x ON x.TableName = c.TABLE_NAME
	WHERE c.TABLE_SCHEMA = 'dbo'
	----D-02339
	AND t.TABLE_TYPE = 'VIEW'
	--AND t.TABLE_TYPE = 'BASE TABLE'
	----TK-03298 TK-03298 TK-03569
	--AND c.TABLE_NAME IN ('bINMO', 'bPMDG', 'bPMDL', 'bPMDR', 'bPMIL', 'bPMIM', 'bPMMM', 'bPMOD', 'bPMOH', 'bPMOP',
	--					 'bPMPN', 'bPMPU', 'bPMRI', 'bPMSI', 'bPMSM', 'bPMTL', 'bPMTM', 'bPOHD', 'SLHD',
	--					 'vPMSubcontractCO', 'vPMChangeOrderRequest', 'vPMPOCO')
	AND s.is_user_defined = 0
	AND c.DATA_TYPE NOT IN ('image', 'text', 'uniqueidentifier', 'sql_variant', 'xml')
	AND c.COLUMN_NAME <> 'KeyID'
	AND EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.COLUMNS x WHERE x.TABLE_SCHEMA=c.TABLE_SCHEMA
				AND x.TABLE_NAME=c.TABLE_NAME AND x.COLUMN_NAME = 'KeyID')
				
				
	--SELECT TableName, ColumnName FROM @PMTableColumns ORDER BY TableName, ColumnName
	--RETURN

	---- build parameters
	SET @ParamsDef = NULL	   
	SET @ParamsDef = '@TableName NVARCHAR(128), @ColumnName NVARCHAR(128), @KeyID NVARCHAR(10), @TextStr NVARCHAR(110)'

	---- search columns for key word and update temp table
	SELECT @TableName = MIN(TableName) FROM @PMTableColumns
	WHILE @TableName IS NOT NULL
		BEGIN

		SELECT @ColumnName = MIN(ColumnName) FROM @PMTableColumns where TableName=@TableName
		WHILE @ColumnName IS NOT NULL
		BEGIN

			--SET @Query = 'INSERT INTO ##SearchResults (TableName, ColumnName, ColumnValue, KeyID) '
			--		   + 'SELECT ''' + @TableName + ''', ''' +  @ColumnName + ''', LEFT(' + @ColumnName + ', 400), CONVERT(NVARCHAR, ' + @KeyID + ') '
			--		   + 'FROM ' + @TableName + ' (NOLOCK) WHERE LOWER(CONVERT(VARCHAR(MAX), @ColumnName, 101)) LIKE @TextStr'	
			--------execute dynamic sql
			--	---- build parameters
			--SET @ParamsDef = NULL	   
			--SET @ParamsDef = '@TableName NVARCHAR(128), @ColumnName NVARCHAR(128), @KeyID NVARCHAR(128), @TextStr NVARCHAR(110)'
			--exec sp_executesql @Query, @ParamsDef, @TableName, @ColumnName, @KeyID, @TextStr
			
		---- text search
		INSERT INTO ##SearchResults
			EXEC
		----PRINT
			(
				'SELECT ''' + @TableName + ''', ''' +  @ColumnName + ''', LEFT(' + @ColumnName + ', 400), CONVERT(NVARCHAR, ' + @KeyID + ') '
				+ ' FROM ' + @TableName + ' (NOLOCK) WHERE LOWER(CONVERT(VARCHAR(MAX), ' + @ColumnName + ', 101))' + ' LIKE ' + @TextStr
			)
			
				
		---- next column
		SELECT @ColumnName = MIN(ColumnName) FROM @PMTableColumns WHERE TableName=@TableName AND ColumnName>@ColumnName
		IF @@rowcount = 0 SET @ColumnName = NULL
		END

		---- next table
		SELECT @TableName = MIN(TableName) FROM @PMTableColumns WHERE TableName > @TableName
		IF @@rowcount = 0 SET @TableName = NULL
		END
		
	---- delete duplicate rows from search results. possible multiple columns have key word
	DELETE a
	FROM ##SearchResults a
	INNER JOIN ##SearchResults b ON b.TableName=a.TableName AND b.KeyID=a.KeyID
	WHERE b.TableName=a.TableName AND b.KeyID=a.KeyID AND b.ColumnName > a.ColumnName
			
	END
	
	
---- populate with Table Range for Vendor or Firm
IF ISNULL(@TypeOfSearch,'') = 'V'
	BEGIN
	
	---- populate vendor column table
	----Vendor Master
	SET @TableName = 'dbo.APVM'
	SET @VendorGroup = 'VendorGroup'
	SET @Number = 'Vendor'
	SET @Name = 'Name'

	INSERT INTO #VendorColumns
		EXEC
		(
			'SELECT ''' + @TableName + ''', CONVERT(NVARCHAR, ' + @VendorGroup + '), CONVERT(NVARCHAR, ' + @Number + '), LEFT(' + @Name + ', 60), CONVERT(NVARCHAR, ' + @KeyID + ') '
			+ ' FROM ' + @TableName + ' (NOLOCK) WHERE LOWER(CONVERT(VARCHAR(MAX), ' + @Number + ', 101))' + ' LIKE ' + @TextStr
			+ ' OR LOWER(CONVERT(VARCHAR(MAX), ' + @Name + ', 112))' + ' LIKE ' + @TextStr
		)

	----Firm Master
	SET @TableName = 'dbo.PMFM'
	SET @Number = 'FirmNumber'
	SET @Name = 'FirmName'

	INSERT INTO #VendorColumns
		EXEC
		(
			'SELECT ''' + @TableName + ''', CONVERT(NVARCHAR, ' + @VendorGroup + '), CONVERT(NVARCHAR, ' + @Number + '), LEFT(' + @Name + ', 60), CONVERT(NVARCHAR, ' + @KeyID + ') '
			+ ' FROM ' + @TableName + ' (NOLOCK) WHERE LOWER(CONVERT(VARCHAR(MAX), ' + @Number + ', 101))' + ' LIKE ' + @TextStr
			+ ' OR LOWER(CONVERT(VARCHAR(MAX), ' + @Name + ', 101))' + ' LIKE ' + @TextStr
		)

	----SELECT * FROM #VendorColumns
	----RETURN
	
	---- populate with Table Range - depends on the type of search
	INSERT INTO @PMTableColumns (TableName, ColumnName)
	SELECT c.TABLE_SCHEMA + '.' + c.TABLE_NAME, c.COLUMN_NAME
	FROM INFORMATION_SCHEMA.COLUMNS c
	INNER JOIN INFORMATION_SCHEMA.TABLES t ON t.TABLE_SCHEMA=c.TABLE_SCHEMA AND t.TABLE_NAME=c.TABLE_NAME
	INNER JOIN sys.types s ON s.name=c.DATA_TYPE
	INNER JOIN @TablesToSearch x ON x.TableName = c.TABLE_NAME
	WHERE c.TABLE_SCHEMA = 'dbo'
	AND t.TABLE_TYPE = 'VIEW'
	--AND t.TABLE_TYPE = 'BASE TABLE'
	AND c.DOMAIN_NAME IN ('bVendor', 'bFirm')
	----TK-03298 TK-03298 TK-03569
	--AND c.TABLE_NAME IN ('bINMO', 'bPMDG', 'bPMDL', 'bPMDR', 'bPMIL', 'bPMIM', 'bPMMM', 'bPMOD', 'bPMOH',
	--					 'bPMOP', 'bPMPN', 'bPMPU', 'bPMRI', 'bPMSI', 'bPMSM', 'bPMTL', 'bPMTM', 'bPOHD',
	--					 'SLHD', 'vPMChangeOrderRequest', 'vPMPOCO', 'vPMSubcontractCO')
	--AND s.is_user_defined = 0
	AND c.DATA_TYPE NOT IN ('image', 'text', 'uniqueidentifier', 'sql_variant', 'xml')
	AND c.COLUMN_NAME <> 'KeyID'
	AND EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.COLUMNS x WHERE x.TABLE_SCHEMA=c.TABLE_SCHEMA
				AND x.TABLE_NAME=c.TABLE_NAME AND x.COLUMN_NAME = 'KeyID')
	AND EXISTS(SELECT TOP 1 1 FROM INFORMATION_SCHEMA.COLUMNS y WHERE y.TABLE_SCHEMA=c.TABLE_SCHEMA
				AND y.TABLE_NAME=c.TABLE_NAME AND y.COLUMN_NAME = 'VendorGroup')


	----SELECT TableName, ColumnName FROM @PMTableColumns ORDER BY TableName, ColumnName
	----RETURN

	---- search columns for key word and update temp table
	SELECT @TableName = MIN(TableName) FROM @PMTableColumns
	WHILE @TableName IS NOT NULL
	BEGIN
		
		SELECT @ColumnName = MIN(ColumnName) FROM @PMTableColumns where TableName=@TableName
		WHILE @ColumnName IS NOT NULL
		BEGIN
		
		---- text search
		INSERT INTO ##SearchResults
			EXEC
		--PRINT
			(
				'SELECT DISTINCT ''' + @TableName + ''', ''' +  @ColumnName + ''', LEFT(' + @ColumnName + ', 400), CONVERT(NVARCHAR, ' + @KeyID + ') '
				+ ' FROM ' + @TableName + ' t INNER JOIN ' + @VendorSearch + ' x ON x.Number = t.' + @ColumnName + ' AND x.VendorGroup = t.' + @VendorGroup
			)
			
		---- next column
		SELECT @ColumnName = MIN(ColumnName) FROM @PMTableColumns WHERE TableName=@TableName AND ColumnName>@ColumnName
		IF @@rowcount = 0 SET @ColumnName = NULL
		END

		---- next table
		SELECT @TableName = MIN(TableName) FROM @PMTableColumns WHERE TableName > @TableName
		IF @@rowcount = 0 SET @TableName = NULL
		END
	END


--SELECT TableName, ColumnName, ColumnValue, KeyID FROM ##SearchResults




GO
GRANT EXECUTE ON  [dbo].[vspPMRecordRelateKeyWordSearch] TO [public]
GO
