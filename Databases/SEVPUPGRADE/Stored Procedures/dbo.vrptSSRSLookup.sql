SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		huyh
-- Create date: 8/30/11
-- Description:	Stored proc that create a dynamic SQL 
--				to create a dataset for lookups in DDLH/DDLD for SSRS 
-- =============================================
CREATE PROCEDURE [dbo].[vrptSSRSLookup]
	@Lookup		varchar(255)
	,@para1		varchar(50) = NULL
	,@para2		varchar(50) = NULL
	,@para3		varchar(50) = NULL
	,@para4		varchar(50) = NULL
	,@para5		varchar(50) = NULL
	,@para6		varchar(50) = NULL
	,@para7		varchar(50) = NULL
	,@para8		varchar(50) = NULL
	,@para9		varchar(50) = NULL
	,@para10	varchar(50) = NULL
	,@para11	varchar(50) = NULL
	,@para12	varchar(50) = NULL
	,@para13	varchar(50) = NULL
	,@para14	varchar(50) = NULL
	,@para15	varchar(50) = NULL
	,@para16	varchar(50) = NULL
	,@para17	varchar(50) = NULL
	,@para18	varchar(50) = NULL
	,@para19	varchar(50) = NULL
	,@para20	varchar(50) = NULL

AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @Sql varchar(max)
	DECLARE @Columns varchar(max)
	DECLARE @WhereClause varchar(max)
	DECLARE @index int
	DECLARE @WhereClauseTable TABLE
	(
		ID int IDENTITY(1,1) PRIMARY KEY,
		WhereClausePart varchar(max)
	)
	DECLARE @ParameterTable TABLE
	(
		ID int IDENTITY(1,1) PRIMARY KEY,
		ParameterName varchar(max)
	)
	DECLARE @ParameterList varchar(max)

	set @para1 = REPLACE(@para1, 'N', '')
	--@para1 = REPLACE(@para1, '''', '')

	SELECT @ParameterList =	ISNULL(@para1,'') + ';' + ISNULL(@para2,'') + ';' + ISNULL(@para3, '') + ';' + ISNULL(@para4,'') + ';' + ISNULL(@para5,'') + ';' + 
						ISNULL(@para6,'') + ';' + ISNULL(@para7,'') + ';' + ISNULL(@para8,'') + ';' + ISNULL(@para9,'') + ';' + ISNULL(@para10,'') + ';' + 
						ISNULL(@para11,'') + ';' + ISNULL(@para12,'') + ';' + ISNULL(@para13,'') + ';' + ISNULL(@para14,'') + ';' + ISNULL(@para15,'') + ';' + 
						ISNULL(@para16,'') + ';' + ISNULL(@para17,'') + ';' + ISNULL(@para18,'') + ';' + ISNULL(@para19,'') + ';' + ISNULL(@para20,'')
	
	SELECT @Sql = 'SELECT '
	SELECT @WhereClause = ISNULL((SELECT WhereClause FROM DDLH WHERE [Lookup] = @Lookup), '')
	
	--String splitter for input parameters
	SET @index = -1
	WHILE (LEN(@ParameterList) > 0)
			BEGIN 
				SET @index = CHARINDEX(';' , @ParameterList) 
				IF (@index = 0) AND (LEN(@ParameterList) > 0) 
				BEGIN  
					INSERT INTO @ParameterTable VALUES (@ParameterList)
					BREAK 
				END 
				IF (@index > 1) 
				BEGIN  
					INSERT INTO @ParameterTable VALUES (LEFT(@ParameterList, @index - 1))  
					SET @ParameterList = RIGHT(@ParameterList, (LEN(@ParameterList) - @index)) 
				END 
				ELSE
					SET @ParameterList = RIGHT(@ParameterList, (LEN(@ParameterList) - @index))
			END
	--/*DEBUG*/select * from @ParameterTable
	
	--Create Null values for optional parameters dependant on 
	--comparison of parameter count in DDLH-WhereClause and count of entered input parameters
	declare @CountOfParametersInWhereClause int
		SELECT @CountOfParametersInWhereClause = LEN(WhereClause)-LEN(REPLACE(WhereClause,'?',''))
		FROM DDLH
		WHERE [Lookup] = @Lookup
		
	declare @CountOfParametersInputParameter int
		SELECT @CountOfParametersInputParameter = COUNT(ID) 
		FROM @ParameterTable 
		WHERE ParameterName <> ''		
	
	IF @CountOfParametersInWhereClause <> @CountOfParametersInputParameter
	BEGIN
		declare @i int
		set @i = 0
		while (@i<@CountOfParametersInWhereClause-@CountOfParametersInputParameter)
			begin
				insert into @ParameterTable values ('null')
				set @i = @i + 1
			end
	END
	--/*DEBUG*/select * from @ParameterTable
	
	--String splitter for lookup parameters in DDLH
	SET @index = -1
	IF @WhereClause LIKE '%?%'
	BEGIN
		WHILE (LEN(@WhereClause) > 0)
			BEGIN 
				SET @index = CHARINDEX('?' , @WhereClause) 
				IF (@index = 0) AND (LEN(@WhereClause) > 0) 
				BEGIN  
					INSERT INTO @WhereClauseTable VALUES (@WhereClause)
					BREAK 
				END 
				IF (@index > 1) 
				BEGIN  
					INSERT INTO @WhereClauseTable VALUES (LEFT(@WhereClause, @index - 1))  
					SET @WhereClause = RIGHT(@WhereClause, (LEN(@WhereClause) - @index)) 
				END 
				ELSE
					SET @WhereClause = RIGHT(@WhereClause, (LEN(@WhereClause) - @index))
			END

		SELECT @WhereClause = '' 
		SELECT @WhereClause =	COALESCE(@WhereClause + '', '') + 
								ISNULL(w.WhereClausePart,'') + 
								ISNULL(p.ParameterName,'') 
		FROM @WhereClauseTable w
		LEFT JOIN @ParameterTable p	
			ON p.ID = w.ID
	END	
	
	--/*DEBUG:*/ select * from @WhereClauseTable
	
	--Create dynamic SQLStatement 
	SELECT @Columns = COALESCE(@Columns + ', ', '') + ColumnName + ' AS ' + '[' + ColumnHeading + ']'
	FROM DDLD 
	WHERE [Lookup] = @Lookup
	
	SELECT @Sql =	CASE 
						WHEN @WhereClause <> '' THEN 
							@Sql + 
							@Columns + 
							' FROM ' + 
							ISNULL((SELECT FromClause FROM DDLH WHERE [Lookup] = @Lookup), '') + 
							ISNULL((SELECT JoinClause FROM DDLH WHERE [Lookup] = @Lookup), '') + 
							' WHERE ' +
							@WhereClause
						ELSE @Sql + 
							@Columns + 
							' FROM ' + 
							ISNULL((SELECT FromClause FROM DDLH WHERE [Lookup] = @Lookup), '') + 
							ISNULL((SELECT JoinClause FROM DDLH WHERE [Lookup] = @Lookup), '')  
					END
	
	--/*DEBUG:*/SELECT @Sql as SqlStatement
	EXECUTE (@Sql)
END

GO
GRANT EXECUTE ON  [dbo].[vrptSSRSLookup] TO [public]
GO
