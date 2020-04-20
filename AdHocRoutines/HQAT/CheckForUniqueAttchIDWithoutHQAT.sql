USE Viewpoint
go

SET NOCOUNT ON

DECLARE atcur CURSOR for
SELECT 
	'[' + so.TABLE_SCHEMA + '].['+ so.TABLE_NAME + ']' AS TableName
,	sc.COLUMN_NAME AS ColumnName
,	'INSERT #tmpAttachmentList (TableName, RecCount) SELECT ''' + so.TABLE_SCHEMA + '.' + so.TABLE_NAME + ''' AS Tbl, COUNT(*) AS MissingCount FROM [' + so.TABLE_SCHEMA + '].['+ so.TABLE_NAME + '] a WHERE ' + sc.COLUMN_NAME + ' IS NOT NULL and NOT EXISTS (select 1 from HQAT b where a.' + sc.COLUMN_NAME + '=b.' + sc.COLUMN_NAME+ ')' --+ sc.name + ' NOT IN ( SELECT DISTINCT ' + sc.name + ' FROM HQAT)'
,	'UPDATE [' + so.TABLE_SCHEMA + '].['+ so.TABLE_NAME + '] set ' + sc.COLUMN_NAME + '=null WHERE '+ sc.COLUMN_NAME + ' IS NOT NULL and NOT EXISTS (select 1 from HQAT b where [' + so.TABLE_SCHEMA + '].['+ so.TABLE_NAME + '].' + sc.COLUMN_NAME + '=b.' + sc.COLUMN_NAME + ')' --+ sc.name + ' NOT IN ( SELECT DISTINCT ' + sc.name + ' FROM HQAT)'
FROM 
	INFORMATION_SCHEMA.TABLES so
JOIN INFORMATION_SCHEMA.COLUMNS sc ON
	so.TABLE_CATALOG=sc.TABLE_CATALOG
AND so.TABLE_SCHEMA=sc.TABLE_SCHEMA
AND so.TABLE_NAME=sc.TABLE_NAME
WHERE
	so.TABLE_TYPE='BASE TABLE'
AND sc.COLUMN_NAME='UniqueAttchID'
AND sc.DATA_TYPE='uniqueidentifier'
AND UPPER(so.TABLE_NAME) NOT LIKE '%$%'
AND UPPER(so.TABLE_NAME) NOT LIKE '%AP%'
AND UPPER(so.TABLE_NAME) NOT LIKE '%HQAT%'
--AND UPPER(so.TABLE_NAME) NOT LIKE '%TEMP%'
--AND UPPER(so.TABLE_NAME) NOT LIKE '%_BU%'
--AND UPPER(so.TABLE_NAME) NOT LIKE '%BAK%'
ORDER BY
	so.TABLE_SCHEMA
,	so.TABLE_NAME
FOR READ ONLY

DECLARE @tbl VARCHAR(255) 
DECLARE @col sysname
DECLARE @selsql VARCHAR(MAX)
DECLARE @updsql VARCHAR(MAX)

CREATE TABLE #tmpAttachmentList
(
	TableName	sysname	NULL
,	RecCount	INT
)

OPEN atcur
FETCH atcur INTO @tbl,@col,@selsql,@updsql

WHILE @@FETCH_STATUS=0
BEGIN
	PRINT
		'--'
	+	CAST(@tbl AS CHAR(40))
	+	CAST(@col AS CHAR(40))
	--+	@selsql

	PRINT @updsql
	PRINT 'GO'

	EXEC ( @selsql )

	FETCH atcur INTO @tbl,@col,@selsql,@updsql
END 

CLOSE atcur
DEALLOCATE atcur

SELECT * FROM #tmpAttachmentList WHERE RecCount<>0 ORDER BY TableName

DROP TABLE #tmpAttachmentList
go




