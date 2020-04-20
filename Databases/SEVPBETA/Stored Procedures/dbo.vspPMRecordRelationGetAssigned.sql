SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/**********************************************************/
CREATE procedure [dbo].[vspPMRecordRelationGetAssigned]
/************************************************************************
* Created By:	GF 11/30/2010 
* MODIFIED By:	GF 06/21/2011 D-02339 use views not tables
*
* Purpose of Stored Procedure
*
*    
* 
* Inputs
* @FromKeyID		- KeyID of Related Document
* @FromFormName		- name of calling form
*
* Outputs
* @rcode		- 0 = successfull - 1 = error
* @errmsg		- Error Message
*
*************************************************************************/

(@Co INT = NULL, @FromKeyID bigint = NULL, @FromFormName NVARCHAR(128) = NULL,
 @msg varchar(255) output)

--with execute as 'viewpointcs'

AS
SET NOCOUNT ON

DECLARE @rcode	int, @APCo	int, @INCo	INT, @SQL NVARCHAR(2000),
		@FromFormTable NVARCHAR(128), @RecCount INT

SET @rcode = 0
SET @RecCount = 0

-------------------------------
-- CHECK INCOMING PARAMETERS --	
-------------------------------
IF @FromKeyID IS NULL
	BEGIN
		SET @msg = 'Missing From Form Record ID!'
		SET @rcode = 1
		GOTO vspExit
	END

---- need a from form name
IF ISNULL(@FromFormName,'') = ''
	BEGIN
	SELECT @msg = 'Missing From Form Name parameter!', @rcode = 1
	GOTO vspExit
	END

---- execute SP to get the from form table
EXEC @rcode = dbo.vspPMRecordRelationGetFormTable @FromFormName, @FromFormTable output, @msg output

---- must have a form name
IF @FromFormTable IS NULL
	BEGIN
	SELECT @msg = 'Missing From Form Table for related records!', @rcode = 1
	GOTO vspExit
	END
	

----------------------
-- GET OTHER VALUES --
----------------------
SELECT @APCo = APCo, @INCo = INCo
FROM dbo.bPMCO WHERE PMCo = @Co
IF @@ROWCOUNT = 0
	BEGIN
	SET @APCo = @Co
	SET @INCo = @Co
	END

---- create a temp table with all tables to search
DECLARE @TablesToSearch table 
( 
    PK				int IDENTITY(1,1),  
	RecordType		NVARCHAR(60),
	Detail			NCHAR(1),
	TypeColumn1		NVARCHAR(128),
	KeyColumn1		NVARCHAR(128),
	DateColumn1		NVARCHAR(128),
	DescColumn1		NVARCHAR(128),
	DefaultType		NVARCHAR(30)
) 


---- populate @TablesToSearch from vDDFormRelated
---- will be related for the @FromFormName
INSERT INTO @TablesToSearch (RecordType, Detail, TypeColumn1, KeyColumn1, DateColumn1, DescColumn1, DefaultType)
SELECT f.RelatedForm, i.Detail, i.TypeColumn1, i.KeyColumn1, i.DateColumn1, i.DescColumn1, i.DefaultTypeDesc
FROM dbo.vDDFormRelated f
INNER JOIN dbo.vDDFormRelatedInfo i ON f.RelatedForm=i.Form
WHERE f.Form = @FromFormName



---- loop through rows in #TablesToSearch
DECLARE @TableName NVARCHAR(128), @RecordType NVARCHAR(60), @TypeColumn1 NVARCHAR(128),
		@Detail NCHAR(1), @KeyColumn1 NVARCHAR(128), @DateColumn1 NVARCHAR(128),
		@DescColumn1 NVARCHAR(128), @DefaultType NVARCHAR(30)
Declare @maxPK int;Select @maxPK = MAX(PK) From @TablesToSearch 
Declare @PK int;Set @PK = 1 


---- drop global temp table for search results if exists
If Object_Id('tempdb..#relatd_records') IS NOT NULL
	begin
	DROP TABLE #relatd_records
	END
	
---- CREATE TEMP TABLE TO HOLD RELATED RECORDS
create table #related_records
(
	RecType			NVARCHAR(60),
	KeyID			BIGINT,
	LinkID			BIGINT,
	FormKeyID		BIGINT,
	Detail			NCHAR(1),
	DocType			NVARCHAR(60),
	DocID			NVARCHAR(60),
	RecDate			NVARCHAR(30),
	RecDesc			NVARCHAR(100)
)


---- loop through tables to search
WHILE @PK <= @maxPK 
BEGIN 
 
    /* Get one record (you can read the values into some variables) */ 
    Select @RecordType = RecordType, @TypeColumn1 = TypeColumn1,
			@Detail = ISNULL(Detail,'N'), @KeyColumn1 = KeyColumn1,
			@DateColumn1 = DateColumn1, @DescColumn1 = DescColumn1,
			@DefaultType = ISNULL(DefaultType,'')
    FROM @TablesToSearch Where PK = @PK
	
	
	---- execute SP to get the form table (RecordType)
	SET @TableName = NULL
	EXEC @rcode = dbo.vspPMRecordRelationGetFormTable @RecordType, @TableName output, @msg output
	IF ISNULL(@TableName,'') = '' GOTO next_table_search

	---- build query statement to search
	SET @SQL = NULL
	SET @SQL = 'SELECT ' + CHAR(39) + @RecordType + CHAR(39) + ' AS [RecType], '
			+  CONVERT(NVARCHAR(30),@FromKeyID) + ' AS [KeyID], '
			+  'CAST(r.KeyID AS NVARCHAR(30)) AS [LinkID], '
		
	---- possible different FormKeyID when showing detail (i.e. bPMDR to bPMDG) for drawing revisions
	IF @Detail = 'N'
		BEGIN
		SET @SQL = @SQL + 'CAST(r.KeyID AS NVARCHAR(30)) AS [FormKeyID], '
		END
	ELSE
		BEGIN
		IF @TableName = 'APTL'
			BEGIN
			SET @SQL = @SQL + 'CAST(-1 AS NVARCHAR(30)) AS [FormKeyID], '
			END
		ELSE
			BEGIN
			SET @SQL = @SQL + 'CAST(ISNULL(m.KeyID,r.KeyID) AS NVARCHAR(30)) AS [FormKeyID], '
			END
		END
	
	---- DETAIL FLAG
	SET @SQL = @SQL	+ CHAR(39) + @Detail + CHAR(39) + ' AS [Detail], '
		
	---- document type column
	IF @TypeColumn1 IS NOT NULL
		BEGIN
		IF @RecordType = 'PMProjectIssues'
			BEGIN
			SET @SQL = @SQL +  'CAST(ISNULL(r.' + @TypeColumn1 + ',' + CHAR(39) + @DefaultType + CHAR(39) + ') AS NVARCHAR(30)) AS [DocType], '
			END
		ELSE
			BEGIN
			SET @SQL = @SQL +  'CAST(r.' + @TypeColumn1 + ' AS NVARCHAR(30)) AS [DocType], '
			END
		END
	ELSE
		BEGIN
		SET @SQL = @SQL + CHAR(39) + @DefaultType + CHAR(39) + 'AS [DocType], '
		END
		
	---- key column
	IF @KeyColumn1 IS NOT NULL
		BEGIN
		IF @TableName = 'APTL'
			BEGIN
			SET @SQL = @SQL + 'CAST(m.' + @KeyColumn1 + ' AS NVARCHAR(30)) AS [DocID], '
			END
		ELSE
			BEGIN
			SET @SQL = @SQL + 'CAST(r.' + @KeyColumn1 + ' AS NVARCHAR(30)) AS [DocID], '
			END
		END
	ELSE
		BEGIN
		SET @SQL = @SQL + 'NULL AS [DocID], ' 
		END
	
	---- date column
	IF @DateColumn1 IS NOT NULL
		BEGIN
		IF @TableName = 'APTL'
			BEGIN
			SET @SQL = @SQL + 'dbo.vfDateOnlyAsStringUsingStyle(m.' + @DateColumn1 + ', ' + CONVERT(VARCHAR(3),@Co) + ', DEFAULT) AS [RecDate], '
			END
		ELSE
			BEGIN
			SET @SQL = @SQL + 'dbo.vfDateOnlyAsStringUsingStyle(r.' + @DateColumn1 + ', ' + CONVERT(VARCHAR(3),@Co) + ', DEFAULT) AS [RecDate], '
			END
		END
	ELSE
		BEGIN
		SET @SQL = @SQL + CHAR(39) + CHAR(39) + ' AS [RecDate], '
		END
		
	---- description column
	IF @DescColumn1 IS NOT NULL
		BEGIN
		SET @SQL = @SQL + 'CAST(r.' + @DescColumn1 + ' AS NVARCHAR(100)) AS [RecDesc] '
		END
	ELSE
		BEGIN
		SET @SQL = @SQL + CHAR(39) + CHAR(39) + ' AS [RecDesc] '
		END
	
	
	---- from statement
	SET @SQL = @SQL + 'FROM dbo.' + @TableName + ' r WITH (NOLOCK) '
	
	---- detail to parent join statement
	IF @TableName = 'PMDR'
		BEGIN
		---- drawing revisions
		SET @SQL = @SQL + 'JOIN dbo.PMDG m ON m.PMCo=r.PMCo AND m.Project=r.Project AND m.DrawingType=r.DrawingType AND m.Drawing=r.Drawing'
		END
	
	IF @TableName = 'PMSI'
		BEGIN
		---- submittal items
		SET @SQL = @SQL + 'JOIN dbo.PMSM m ON m.PMCo=r.PMCo AND m.Project=r.Project AND m.SubmittalType=r.SubmittalType AND m.Submittal=r.Submittal AND m.Rev=r.Rev'
		END
		
	IF @TableName = 'APTL'
		BEGIN
		---- ap invoice detail
		SET @SQL = @SQL + 'join dbo.APTH m on m.APCo=r.APCo and m.Mth=r.Mth and m.APTrans=r.APTrans'
		END
	
	---- build where clause, most will be PM company and project except for bINMO, SLHD, bPOHD
	SET @SQL = @SQL + ' WHERE (EXISTS(SELECT TOP 1 1 FROM dbo.PMRelateRecord v WHERE v.RecTableName  = ' + CHAR(39) + @TableName + CHAR(39)
		+  ' AND v.RECID =  r.KeyID  AND v.LinkTableName = ' + CHAR(39) + @FromFormTable + CHAR(39) + ' AND v.LINKID = ' + CONVERT(VARCHAR(10),@FromKeyID) + ')'
		+  ' OR EXISTS(SELECT TOP 1 1 FROM dbo.PMRelateRecord w WHERE w.LinkTableName = ' + CHAR(39) + @TableName + CHAR(39)
		+  ' AND w.LINKID = r.KeyID AND  w.RecTableName  = ' + CHAR(39) + @FromFormTable + CHAR(39) + ' AND w.RECID  = ' + CONVERT(VARCHAR(10),@FromKeyID) + '))'

	IF @SQL IS NOT NULL
		BEGIN
			INSERT INTO #related_records
			EXEC (@SQL)
			----PRINT (@SQL)
		END
	
	---- next table to search
	next_table_search:
	SET @PK = @PK + 1
		
END 


--SELECT @RecCount = (SELECT COUNT(*) FROM #related_records)
--SELECT @msg = ISNULL(@FromFormName,'') + ', ' + ISNULL(@FromFormTable,'') + ', ' + CONVERT(VARCHAR(10), @FromKeyID) + ', ' + CONVERT(VARCHAR(10),@RecCount)
--SET @rcode = 1
--GOTO vspExit

---- RETURN RESULTS
---- FORM HEADINGS: Record Type	KeyID	LinkID	FormKeyID	Detail	Doc Type	Doc ID	Date	Description
SELECT RecType AS [Record Type], KeyID AS [KeyID], LinkID AS [LinkID], FormKeyID AS [FormKeyID],
		Detail AS [Detail], DocType AS [Doc Type], DocID AS [Doc ID], RecDate AS [Date], RecDesc AS [Description]
FROM #related_records
ORDER BY RecType, KeyID, LinkID
	




vspExit:
	RETURN @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPMRecordRelationGetAssigned] TO [public]
GO
