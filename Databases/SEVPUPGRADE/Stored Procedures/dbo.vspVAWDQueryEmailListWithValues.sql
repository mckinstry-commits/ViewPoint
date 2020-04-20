SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [dbo].[vspVAWDQueryEmailListWithValues]
  /************************************************************************
  * CREATED: 	HH 10/17/12  TK-18458 
  * MODIFIED:   
  *
  * Purpose of Stored Procedure:	return sample values for email field dialog
  * 
  *
  * returns 0 if successfull 
  * returns 1 and error msg if failed
  *
  *************************************************************************/
          
(@queryname varchar(150), @querytype int = 0, @jobname varchar(150))

as
set nocount on

declare @rcode int
select @rcode = 0

DECLARE @SampleValue VARCHAR(MAX)
DECLARE @SelectClause VARCHAR(MAX)
DECLARE @FromWhereClause VARCHAR(MAX)

-- WF Notifier Queries		
IF @querytype = 0
BEGIN
	SELECT	@SelectClause = ISNULL(SelectClause,'') 
	,@FromWhereClause = ISNULL(FromWhereClause,'')
	FROM [bWDQY]
	WHERE [QueryName] = @queryname;

	-- Replace params in @FromWhereClause with Input Values from WDJP 
	-- need to order by [Param] Desc (longest string) since sql replace is NOT whole word
	SELECT @FromWhereClause = REPLACE(@FromWhereClause, [Param], InputValue) FROM WDJP WHERE JobName = @jobname ORDER BY [Param] Desc
END	
-- VA Inquiries
ELSE
BEGIN 
	SELECT	@SelectClause = ISNULL(Query,'') 
	,@FromWhereClause = ''
	FROM VPGridQueries
	WHERE [QueryName] = @queryname;

	DECLARE @VAInquiryQueryType INT;
	SELECT @VAInquiryQueryType = QueryType 
	FROM VPGridQueries 
	WHERE QueryName = @queryname;

	-- create and stuff select statement for VA Inquiry type 'view'
	IF @VAInquiryQueryType = 1
	BEGIN
		SELECT @SelectClause =
		'SELECT' + STUFF
		(
			(
				SELECT ', ' + '['+ColumnName+']'
				FROM VPGridColumns C
				WHERE C.QueryName = Q.QueryName
				ORDER BY DefaultOrder
				FOR XML PATH('')
			), 1, 1, ''
		) 
		+ ' FROM '
		+ Q.Query 
		+ ISNULL(' WHERE ' + STUFF
		(
			(
				SELECT ' ' + ISNULL('['+P.ColumnName+']','') + ' ' + ISNULL(P.Comparison,'') + ' ' + ISNULL(P.ParameterName,'') + ' ' + ISNULL(P.Operator,'')
				FROM VPGridQueryParameters P
				WHERE P.QueryName = Q.QueryName
				ORDER BY P.Seq
				FOR XML PATH(''), ROOT('Query'), TYPE 
			).value('/Query[1]','VARCHAR(MAX)'), 1, 1, ''
		), '')
		FROM	VPGridQueries Q
		WHERE	QueryName = @queryname;

		--Remove last and/or
		SET @SelectClause = CASE 
								WHEN (RIGHT(@SelectClause,3) IN ('AND', ' OR'))
								THEN LEFT(@SelectClause, LEN(@SelectClause)-3) 
							END 
	END
	ELSE
	BEGIN
		SELECT @SelectClause = Query FROM VPGridQueries WHERE QueryName = @queryname; 
	END
	-- Replace params in @SelectClause with Input Values from WDJP
	-- need to order by [Param] Desc (longest string) since sql replace is NOT whole word
	SELECT @SelectClause = REPLACE(@SelectClause, [Param], InputValue) FROM WDJP WHERE JobName = @jobname ORDER BY [Param] Desc
END

-- create temp. @tempDataTableName table ---------------------
DECLARE @tempDataTableName VARCHAR(40), @sql NVARCHAR(MAX);
SET @tempDataTableName = '##tmp-' + CONVERT(VARCHAR(36),NEWID());

DECLARE @CreateTmpTable varchar(max)

IF @querytype = 0
BEGIN
	--SET @sql = @SelectClause + ' INTO [' + @tempDataTableName + '] ' + @FromWhereClause;
	--EXEC sp_executesql @sql;
	SET @SelectClause  = @SelectClause + ' ' + @FromWhereClause;
	SET @CreateTmpTable = 
	'CREATE TABLE '+ '['+@tempDataTableName+']' +' (' + STUFF
	(
		(
			SELECT ', ' + '['+TableColumn+']' + ' VARCHAR(MAX)'
			FROM WDQF C
			WHERE QueryName = @queryname
			ORDER BY Seq
			FOR XML PATH('')
		), 1, 1, ''
	) + ' ) ' 
END
ELSE IF @querytype = 1
BEGIN
	SET @CreateTmpTable = 
	'CREATE TABLE '+ '['+@tempDataTableName+']' +' (' + STUFF
	(
		(
			SELECT ', ' + '['+ColumnName+']' + ' VARCHAR(MAX)'
			FROM VPGridColumns C
			WHERE QueryName = @queryname
			ORDER BY DefaultOrder
			FOR XML PATH('')
		), 1, 1, ''
	) + ' ) ' 
END

SET @sql = @CreateTmpTable + ' INSERT TOP(1) INTO ' + '['+@tempDataTableName+']' +' EXEC sp_executesql N' + ''''+REPLACE(@SelectClause, '''', '''''')+''''
EXEC sp_executesql @sql; 

-- no data
IF OBJECT_ID('tempdb..'+@tempDataTableName) is null
goto noparameter

---as dynamic sql
IF @querytype = 0
BEGIN
	SELECT @sql =
		'with unpivotcte
		as
		(
			select ColumnName, ColumnValue
			from
			(
			select' + STUFF
			(
				(
					SELECT ', ' + '['+TableColumn+']'
					FROM WDQF C
					WHERE C.QueryName = @queryname
					ORDER BY Seq
					FOR XML PATH('')
				), 1, 1, ''
			) 
			+ ' FROM ' + '['+@tempDataTableName+']'
			+ ') p
			unpivot
			(
				ColumnValue For ColumnName in ('
			+ STUFF
			(
				(
					SELECT ', ' + '['+TableColumn+']'
					FROM WDQF C
					WHERE C.QueryName = @queryname
					ORDER BY Seq
					FOR XML PATH('')
				), 1, 1, ''
			) 
			+' )
			)as unpivotcte
		)
		SELECT	WDQF.EMailField
				, WDQF.TableColumn 
				, ISNULL(unpivotcte.ColumnValue, '''') as ColumnValue
		FROM WDQF 
		LEFT OUTER JOIN unpivotcte on unpivotcte.ColumnName = WDQF.TableColumn
		Where WDQF.QueryName = ''' + @queryname + '''
		Order By Seq'
	EXEC sp_executesql @sql; 
END
ELSE IF @querytype = 1
BEGIN
	SELECT @sql =
		'with unpivotcte
		as
		(
			select ColumnName, ColumnValue
			from
			(
			select' + STUFF
			(
				(
					SELECT ', ' + '['+ColumnName+']'
					FROM VPGridColumns C
					WHERE C.QueryName = @queryname
					ORDER BY DefaultOrder
					FOR XML PATH('')
				), 1, 1, ''
			) 
			+ ' FROM ' + '['+@tempDataTableName+']'
			+ ') p
			unpivot
			(
				ColumnValue For ColumnName in ('
			+ STUFF
			(
				(
					SELECT ', ' + '['+ColumnName+']'
					FROM VPGridColumns C
					WHERE C.QueryName = @queryname
					ORDER BY DefaultOrder
					FOR XML PATH('')
				), 1, 1, ''
			) 
			+' )
			)as unpivotcte
		)
		Select	''['' + VPGridColumns.ColumnName + '']'' as EMailField
				, VPGridColumns.ColumnName as TableColumn 
				, ISNULL(unpivotcte.ColumnValue, '''') as ColumnValue
		FROM VPGridColumns 
		LEFT OUTER JOIN unpivotcte on unpivotcte.ColumnName = VPGridColumns.ColumnName
		Where VPGridColumns.QueryName = ''' + @queryname + '''
		Order By DefaultOrder'
	EXEC sp_executesql @sql; 
END

-- delete temp table
SET @sql = 'DROP TABLE ' + QUOTENAME(@tempDataTableName);
EXEC sp_executesql @sql; 


noparameter:
if @querytype = 1
	Select	'[' + ColumnName + ']' as EMailField
			, ColumnName as TableColumn 
			, '' as ColumnValue
	from	VPGridColumns 
	Where	QueryName = @queryname 
	Order By DefaultOrder
else
	Select	EMailField
			, TableColumn 
			, '' as ColumnValue
	from WDQF 
	Where QueryName = @queryname 
	Order By Seq


if @@rowcount = 0
begin
	select @rcode=1
end

bspexit:
return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspVAWDQueryEmailListWithValues] TO [public]
GO
