SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/************************************************************************/
CREATE procedure [dbo].[vspPMRecordRelationGetAvailable]
/************************************************************************
* Created By:	GF 11/29/2010 
* Modified By:  GF 03/29/2011 TK-03298 TK-04796
*				GF 06/21/2011 D-02339 use views not tables
*
*
* Purpose of Stored Procedure is to find available records to related to
* form record. Is currently called from PM stored procedure to get available
* records vspPMRecordRelateRelGetUnRel
*
*
*    
* 
* Inputs
* @Co				- Company NOT NULL
* @Project			- Project (filter) MAY BE NULL
* @FromFormName		- Category to use to find the form name and form table name NOT NULL
* @FromKeyID		- Form key id we are relating records too NOT NULL
* @SearchInTable	- Table to pull specific data from (filter) MAY BE NULL
*
* Outputs
* @rcode		- 0 = successfull - 1 = error
* @msg		- Error Message
*
*************************************************************************/
(@Co bCompany = NULL, @Project bJob = NULL, @FromFormName NVARCHAR(128) = NULL,
 @FromKeyID bigint = NULL, @SearchInTable NVARCHAR(128) = NULL,
 @msg varchar(max) output)

AS
SET NOCOUNT ON

DECLARE @rcode	int, @APCo	int, @INCo	INT, @SQL NVARCHAR(2000),
		@FromFormTable NVARCHAR(128), @Dummy_Project NVARCHAR(30)


SET @rcode = 0
SET @Dummy_Project = 'M!ss!n$'

-------------------------------
-- CHECK INCOMING PARAMETERS --	
-------------------------------
IF  @Co IS NULL 
	BEGIN
	SELECT @msg = 'Missing Company input parameter!', @rcode = 1
	GOTO vspExit
	END
	
IF @FromKeyID IS NULL 
	BEGIN
	SELECT @msg = 'Missing FromKeyID input parameter!', @rcode = 1
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
	
--SELECT @FromFormTable, @FromFormName

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
--SELECT f.TableName, f.RelatedForm, f.Detail, f.TypeColumn1, f.KeyColumn1, f.DateColumn1, f.DescColumn1, f.DefaultTypeDesc
FROM dbo.vDDFormRelated f
INNER JOIN dbo.vDDFormRelatedInfo i ON f.RelatedForm=i.Form
--INNER JOIN INFORMATION_SCHEMA.TABLES t ON t.TABLE_NAME=f.TableName
WHERE f.Form = @FromFormName
AND f.RelatedForm <> 'APEntryDetail'----AND f.TableName = ISNULL(@SearchInTable, f.TableName)
--AND t.TABLE_TYPE = 'BASE TABLE'
--AND t.TABLE_SCHEMA = 'dbo'

---- loop through rows in #TablesToSearch
DECLARE @TableName NVARCHAR(128), @RecordType NVARCHAR(60), @TypeColumn1 NVARCHAR(128),
		@Detail NCHAR(1), @KeyColumn1 NVARCHAR(128), @DateColumn1 NVARCHAR(128),
		@DescColumn1 NVARCHAR(128), @DefaultType NVARCHAR(30)
Declare @maxPK int;Select @maxPK = MAX(PK) From @TablesToSearch 
Declare @PK int;Set @PK = 1 

---- first execute a dummy query statememt so that we get some results
--SET @SQL = 'SELECT NULL AS [Record Type], NULL AS [KeyID], NULL AS [LinkID], NULL as [FormKeyID], NULL AS [Detail],'
--		+ ' NULL AS [Doc Type], NULL AS [Doc ID], NULL AS [Date], NULL AS [Description]'
--		+ ' FROM dbo.bPMCO WITH (NOLOCK) WHERE PMCo= ' + CONVERT(VARCHAR(3),@Co) 
--EXEC (@SQL)

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
	
	
	---- if we are only searching in one table, skip if not the search in table
	IF ISNULL(@SearchInTable,'') <> ''
		BEGIN
		IF @SearchInTable <> @TableName GOTO next_table_search
		END
		
							
	---- build query statement to search
	SET @SQL = NULL 
	SET @SQL = 'SELECT ' + CHAR(39) + @RecordType + CHAR(39) + ' AS [Record Type], NULL AS [KeyID], '
		
		---- detail flag indicates where the key id is from we may be able to use the link id for header key.
		IF @Detail = 'Y'
			BEGIN
			SET @SQL = @SQL + ' h.KeyID as [LinkID], r.KeyID as [FormKeyID], '
			END
		ELSE
			BEGIN
			SET @SQL = @SQL + ' NULL AS [LinkID], r.KeyID as [FormKeyID], '
			END
			
		---- DETAIL FLAG
		SET @SQL = @SQL + CHAR(39) + @Detail + CHAR(39) + ' AS [Detail], '
		
		---- document type column
		IF @TypeColumn1 IS NOT NULL
			BEGIN
			IF @RecordType = 'PMProjectIssues'
				BEGIN
				----SET @SQL = @SQL +  'CAST(ISNULL(r.' + @TypeColumn1 + ',' + CHAR(39) + @DefaultType + CHAR(39) + ') AS NVARCHAR(30)) AS [Doc Type], '
				SET @SQL = @SQL + 'ISNULL(CAST(r.' + @TypeColumn1 + ' AS NVARCHAR(30)), ' + CHAR(39) + @DefaultType + CHAR(39) + ') AS [Doc Type], '
				END
			ELSE
				BEGIN
				SET @SQL = @SQL +  'CAST(r.' + @TypeColumn1 + ' AS NVARCHAR(30)) AS [Doc Type], '
				END
			END
		ELSE
			BEGIN
			SET @SQL = @SQL + CHAR(39) + @DefaultType + CHAR(39) + 'AS [Doc Type], '
			END
			
		---- key column
		IF @KeyColumn1 IS NOT NULL
			BEGIN
			SET @SQL = @SQL + 'CAST(r.' + @KeyColumn1 + ' AS NVARCHAR(30)) AS [Doc ID], '
			END
		ELSE
			BEGIN
			SET @SQL = @SQL + 'NULL AS [Doc ID], ' 
			END
		
		---- date column
		IF @DateColumn1 IS NOT NULL
			BEGIN
			SET @SQL = @SQL + 'dbo.vfDateOnlyAsStringUsingStyle(r.' + @DateColumn1 + ', ' + CONVERT(VARCHAR(3),@Co) + ', DEFAULT) AS [Date], '
			END
		ELSE
			BEGIN
			SET @SQL = @SQL + CHAR(39) + CHAR(39) + ' AS [Date], '
			END
			
		---- description column
		IF @DescColumn1 IS NOT NULL
			BEGIN
			SET @SQL = @SQL + 'CAST(r.' + @DescColumn1 + ' AS NVARCHAR(100)) AS [Description] '
			END
		ELSE
			BEGIN
			SET @SQL = @SQL + CHAR(39) + CHAR(39) + ' AS [Description] '
			END
		
		---- from clause
		SET @SQL = @SQL +  'FROM dbo.' + @TableName + ' r WITH (NOLOCK)'
	
	---- if we have search results then inner join to results for result set
	If Object_Id('tempdb..##SearchResults') IS NOT NULL
		BEGIN
		IF (SELECT COUNT(*) FROM ##SearchResults) > 0
			BEGIN
			DECLARE @SearchTable NVARCHAR(128)
			SET @SearchTable = 'dbo.' + @TableName
			SET @SQL = @SQL + ' INNER JOIN ##SearchResults x ON x.TableName = ' + CHAR(39) + @SearchTable + CHAR(39) + ' AND x.KeyID = r.KeyID'
			END
		END
		
	---- need to join to PMDG for drawing log revisions so form can load
	IF @TableName = 'PMDR'
		BEGIN
		SET @SQL = @SQL + ' INNER JOIN dbo.PMDG h on h.PMCo=r.PMCo and h.Project=r.Project and h.DrawingType=r.DrawingType and h.Drawing=r.Drawing'
		END
	
	---- need to join to PMSM for submittal items so form can load
	IF @TableName = 'PMSI'
		BEGIN
		SET @SQL = @SQL + ' INNER JOIN dbo.PMSM h on h.PMCo=r.PMCo and h.Project=r.Project and h.SubmittalType=r.SubmittalType and h.Submittal=r.Submittal and h.Rev=r.Rev'
		END
		
	---- BUILD WHERE STATEMENT FOR available
	---- exclude existing record relations
	SET @SQL = @SQL + ' WHERE NOT EXISTS(SELECT TOP 1 1 FROM dbo.PMRelateRecord v WHERE v.RecTableName  = ' + CHAR(39) + @TableName + CHAR(39)
		+  ' AND v.RECID =  r.KeyID  AND v.LinkTableName = ' + CHAR(39) + @FromFormTable + CHAR(39) + ' AND v.LINKID = ' + CONVERT(VARCHAR(10),@FromKeyID) + ')'
		+  ' AND NOT EXISTS(SELECT TOP 1 1 FROM dbo.PMRelateRecord w WHERE w.LinkTableName = ' + CHAR(39) + @TableName + CHAR(39)
		+  ' AND w.LINKID = r.KeyID AND  w.RecTableName  = ' + CHAR(39) + @FromFormTable + CHAR(39) + ' AND w.RECID  = ' + CONVERT(VARCHAR(10),@FromKeyID) + ')'
	
	---- add company parameter and job/project to where statement
	IF @TableName = 'INMO'
		BEGIN
		SET @SQL = @SQL
			+  ' AND r.INCo= ISNULL(' + CONVERT(NVARCHAR(3), @INCo) + ', ' + CONVERT(NVARCHAR(3), @Co)+ ') '
			+  ' AND r.JCCo= ' + CONVERT(NVARCHAR(3), @Co)
			+  ' AND r.Job= ISNULL(' + CHAR(39) + @Project + CHAR(39) + ', ' + CHAR(39) + @Dummy_Project + CHAR(39) + ') '
		END
	
	ELSE IF @TableName = 'POHD'
		BEGIN
		SET @SQL = @SQL
			+  ' AND r.POCo= ISNULL(' + CONVERT(NVARCHAR(3), @APCo) + ', ' + CONVERT(NVARCHAR(3), @Co) + ') '
			+  ' AND r.JCCo= ' + CONVERT(NVARCHAR(3), @Co)
			+  ' AND r.Job= ISNULL(' + CHAR(39) + @Project + CHAR(39) + ', ' + CHAR(39) + @Dummy_Project + CHAR(39) + ') '
		END
		
	ELSE IF @TableName = 'SLHD'
		BEGIN
		SET @SQL = @SQL
			+  ' AND r.SLCo= ISNULL(' + CONVERT(NVARCHAR(3), @APCo) + ', ' + CONVERT(NVARCHAR(3), @Co) + ') '
			+  ' AND r.JCCo= ' + CONVERT(NVARCHAR(3), @Co)
			+  ' AND r.Job= ISNULL(' + CHAR(39) + @Project + CHAR(39) + ', ' + CHAR(39) + @Dummy_Project + CHAR(39) + ') '
		END
		
	ELSE IF SUBSTRING(@TableName,1,2) = 'PM'
		BEGIN
		SET @SQL = @SQL + ' AND r.PMCo= ' + CONVERT(VARCHAR(3), @Co)
		IF ISNULL(@Project,'') <> ''
			BEGIN
			----TK-03298
			IF @TableName IN ('PMChangeOrderRequest', 'PMContractChangeOrder', 'PMContractItem')
				BEGIN
				SET @SQL = @SQL + ' AND r.Contract= ISNULL(' + CHAR(39) + @Project + CHAR(39) + ', r.Contract) '
				END
			ELSE	
				BEGIN
				SET @SQL = @SQL + ' AND r.Project= ISNULL(' + CHAR(39) + @Project + CHAR(39) + ', r.Project) '
				END
			END
		END

	IF @TableName = @FromFormTable
		BEGIN
		SET @SQL = @SQL + ' AND r.KeyID <> ' + CONVERT(VARCHAR(20),@FromKeyID)
		----SET @SQL = @SQL + ' AND (@TableName <> @FromFormTable and r.KeyID <> ' + CONVERT(VARCHAR(20),@FromKeyID) + ')'
		END
		
	--PRINT @SQL
	
	exec (@SQL)
	
	---- next table to search
	next_table_search:
	SET @PK = @PK + 1
		
END 




	
		
vspExit:
	RETURN @rcode


GO
GRANT EXECUTE ON  [dbo].[vspPMRecordRelationGetAvailable] TO [public]
GO
