USE [Viewpoint]
GO

/****** Object:  StoredProcedure [dbo].[mspSetNonProdEmailAddresses]    Script Date: 2/18/2015 7:59:55 AM ******/
DROP PROCEDURE [dbo].[mspSetNonProdEmailAddresses]
GO

CREATE PROCEDURE [dbo].[mspSetNonProdEmailAddresses]
(
	@Simulate	bYN	= 'Y'
,	@sysemail VARCHAR(100) = 'erptest@mckinstry.com'
)

AS

/*
2015.02.17 - LWO - Created procedure to update any any all tables that have "real" email addresses to use
				   "erptest@mckinstry.com" so we dont have email notifications being sent to "real" people
				   from our non-production Viewpoint systems.  Procedure will not run from any of the three
				   production SQL servers but can be used anywhere else.

				   Options @Simulate flag will show the data in the system that is a candidate for updating.
				   Also, optional @sysemail will default to "erptest@mckinstry.com" but can be overridden via 
				   procedure parameter.

*/
IF @@SERVERNAME='MCKSQL01\VIEWPOINT' OR @@SERVERNAME='MCKSQL02\VIEWPOINT' OR @@SERVERNAME='SPKSQL01'
BEGIN
	RAISERROR(N'Process not allowed on production servers.',10,1)	
	RETURN -1
END 

SET NOCOUNT ON


DECLARE sqlcur CURSOR for
--SELECT 
--	so.name AS TableName
--,	sc.name AS ColumnName
--,	'select ''' + su.name + '.' + so.name + ''' as TableName, ' + sc.name + ' as EmailAddress from ' + su.name + '.' + so.name + ' where ' + sc.name + ' is not null'
--FROM 
--	sysobjects so JOIN 
--	syscolumns sc ON 
--		so.id=sc.id 
--	AND so.type='U' 
--	AND UPPER(sc.name) LIKE UPPER('EMail')
--	AND so.name NOT LIKE '%_BU'
--	AND so.name NOT LIKE '%_bak_%'
--	AND so.name NOT LIKE '%tmp%' JOIN
--	sysusers su ON
--		so.uid=su.uid
select 
	so.TABLE_SCHEMA AS SchemaName
,	so.TABLE_NAME AS TableName
,	sc.COLUMN_NAME AS ColumnName
,	'select ''' + so.TABLE_SCHEMA + '.' + so.TABLE_NAME + ''' as TableName, ' + sc.COLUMN_NAME + ' as EmailAddress from ' + so.TABLE_SCHEMA + '.' + so.TABLE_NAME + ' where ' + sc.COLUMN_NAME + ' is not null and LOWER(RTRIM(LTRIM(' + sc.COLUMN_NAME + '))) <> ''' + @sysemail + ''''
from 
	INFORMATION_SCHEMA.TABLES so JOIN
	INFORMATION_SCHEMA.COLUMNS sc ON
		so.TABLE_CATALOG='Viewpoint'
	AND so.TABLE_TYPE='BASE TABLE'
	AND	so.TABLE_SCHEMA=sc.TABLE_SCHEMA
	AND so.TABLE_CATALOG=sc.TABLE_CATALOG
	AND so.TABLE_NAME=sc.TABLE_NAME
	AND 
		( 
			UPPER(sc.COLUMN_NAME) LIKE UPPER('EMail')
		OR  UPPER(sc.COLUMN_NAME) LIKE UPPER('EMailTo')
		OR  UPPER(sc.COLUMN_NAME) LIKE UPPER('EMailCc')
		OR  UPPER(sc.COLUMN_NAME) LIKE UPPER('BCC')
		)
	AND so.TABLE_NAME NOT LIKE '%_BU'
	AND so.TABLE_NAME NOT LIKE '%_bak_%'
	AND so.TABLE_NAME NOT LIKE '%_bak%'
	AND so.TABLE_NAME NOT LIKE '%tmp%'
	AND so.TABLE_NAME NOT LIKE 'bold%'
ORDER BY 1
FOR READ ONLY

DECLARE @schema VARCHAR(60)
DECLARE @table VARCHAR(60)
DECLARE @column VARCHAR(60)
DECLARE @sql VARCHAR(1000)
DECLARE @updsql VARCHAR(1000)
DECLARE @reccnt int



OPEN sqlcur
FETCH sqlcur INTO
	@schema
,	@table
,	@column
,	@sql

WHILE @@fetch_status=0
BEGIN
	--PRINT '-- ' + @sql
	EXEC (@sql)
	SELECT @reccnt=@@ROWCOUNT
	IF @reccnt>0
	BEGIN
		SELECT @updsql = 'UPDATE ' + @schema + '.' + @table + ' SET ' + @column + '=LOWER(''' + @sysemail + ''') where ' + @column + ' is not null and LOWER(LTRIM(RTRIM('  + @column + '))) <> LOWER(''' + @sysemail + ''')'
		PRINT '-- ' + @table + '.' + @column + ' = ' + CAST(@reccnt AS VARCHAR(20))
		IF @Simulate='Y'
		begin
			PRINT @updsql
		end
		ELSE
		begin
			EXEC (@updsql)
			PRINT CAST(@@rowcount AS VARCHAR(20)) + ' ' + @schema + '.' + @table + ' Rows Updated'
		end

		SELECT @updsql=NULL

	END
    
	SELECT @reccnt=0

	FETCH sqlcur INTO
		@schema
	,	@table
	,	@column
	,	@sql

END

CLOSE sqlcur
DEALLOCATE sqlcur

GO

GRANT EXEC ON [dbo].[mspSetNonProdEmailAddresses] TO PUBLIC
go



--mspSetNonProdEmailAddresses 'N'
