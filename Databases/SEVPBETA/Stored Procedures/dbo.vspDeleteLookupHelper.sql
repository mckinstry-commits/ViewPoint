SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Francine Taylor
-- Create date: 10/4/2011
-- Description:
--    This is a procedure that should be run by anyone who wants to delete
--    a stored procedure
-- =============================================
CREATE PROCEDURE [dbo].[vspDeleteLookupHelper]
   (@deleteData char(1) = 'N', -- pass in Y if you want the lookup data to be deleted
	@LookupName varchar(100),   -- name of the lookup to be deleted (from vDDLH.Lookup)
	 -- report all table-column combinations that we will be checking
	@ShowAllTablesAndColumns char(1) = 'N',
	@SearchSchema char(1) = 'N', -- search through schema as well?
	@errmsg varchar(50) OUTPUT)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	-- error code will be set to non-zero if there is an error that requires
	-- a rollback on the transaction
	declare @rc int
	SET @rc = 0

	BEGIN TRY

	DECLARE @TableName VARCHAR(255)
	DECLARE @ColName VARCHAR(255)
	DECLARE @cmd NVARCHAR(1000)
	DECLARE @count INT, @string1 varchar(500), @todelete int
	DECLARE @ParamDef nvarchar(1000), @rtnVal nvarchar(1000)

	-- This is the table that produces the report output from this SP.
	IF EXISTS(SELECT * from tempdb..sysobjects where id = object_id('tempdb..#report') and type = 'U')
	BEGIN
	   DROP TABLE #report		/* if this isn't the first time this session */
	END
	create table #report (notes varchar(1000))

	
	IF EXISTS(SELECT * from tempdb..sysobjects where id = object_id('tempdb..#spcolumns') and type = 'U')
	BEGIN
	   DROP TABLE #spcolumns		/* if this isn't the first time this session */
	END
	create table #spcolumns (tablename varchar(500), colname varchar(500))

	-- #formtables contains the names of all tables containing the column 'Form'
	IF EXISTS(SELECT * from tempdb..sysobjects where id = object_id('tempdb..#formtables') and type = 'U')
	BEGIN
	   DROP TABLE #formtables
	END
	create table #formtables (tablename varchar(100))
	INSERT INTO #formtables (tablename) 
	SELECT table_name=sysobjects.name
		FROM sysobjects
		JOIN syscolumns ON sysobjects.id = syscolumns.id
		JOIN systypes ON syscolumns.xusertype=systypes.xusertype
	   WHERE syscolumns.name='Form'
	   and sysobjects.xtype='U'
	
	-------------------------------------------------------------------------------
	--
	--    Report on lookups to be deleted
	--
	-------------------------------------------------------------------------------
	insert into #report (notes) values ('Lookup information for : ' + @LookupName)
	set @todelete = 0
	
	set @count = (SELECT COUNT(*) FROM vDDLH WHERE [Lookup] = @LookupName)
	if @count <> 1 insert into #report (notes) values ('Did not find exactly 1 record in vDDLH')
	
	INSERT INTO #report (notes)
	SELECT 'ACTION: Lookup to be deleted frm vDDLH: ' + ISNULL(Memo,[Title])
	FROM vDDLH WHERE [Lookup] = @LookupName

	INSERT INTO #report (notes)
	SELECT 'ACTION: ' + ColumnHeading + '(Seq #' + CAST(Seq AS varchar(3)) + ') will be deleted from vDDLD for ' + @LookupName
	FROM vDDLD WHERE [Lookup] = @LookupName

	IF @deleteData = 'Y' BEGIN
		BEGIN TRY
			DELETE FROM vDDLD WHERE [Lookup] = @LookupName
			DELETE FROM vDDLH WHERE [Lookup] = @LookupName
		END TRY
		BEGIN CATCH
			SELECT @rc = ERROR_NUMBER()
			SET @errmsg = ERROR_MESSAGE()
			INSERT INTO #report (notes) VALUES ('EXCEPTION: ' + @errmsg)
			INSERT INTO #report (notes) VALUES ('Unable to delete lookup')
			GOTO REPORTIT
		END CATCH
	END

	-------------------------------------------------------------------------------
	--
	--    Look for all tables which contain the names of lookups
	--
	-------------------------------------------------------------------------------

	-- this finds all tables with columns containing 'ookup' as part of the name
	INSERT INTO #spcolumns (tablename, colname)
	SELECT tablename=sysobjects.name, syscolumns.name
		FROM sysobjects 
		JOIN syscolumns ON sysobjects.id = syscolumns.id
		JOIN systypes ON syscolumns.xusertype=systypes.xusertype
	   WHERE sysobjects.xtype='U'
	   and syscolumns.name like '%ookup%'
	   and systypes.name = 'varchar'
	ORDER BY sysobjects.name,syscolumns.colid
	
	DELETE FROM #spcolumns WHERE tablename IN ('vDDLH', 'vDDLD')
	DELETE FROM #spcolumns WHERE colname IN ('LookupParams')
	
	DECLARE DatabaseCursor CURSOR FOR
	SELECT tablename, colname FROM #spcolumns

	OPEN DatabaseCursor

	FETCH NEXT FROM DatabaseCursor INTO @TableName, @ColName
	WHILE @@FETCH_STATUS = 0  
	BEGIN  

		-- are there any for this combination?
		SELECT @cmd = 'SELECT @rtnVal = COUNT(*) FROM ' + @TableName
						+ ' WHERE [' + @ColName + '] = ' + CHAR(39) + @LookupName + CHAR(39)
		Select @ParamDef = '@rtnVal nvarchar(1000) OUTPUT'
		EXEC dbo.sp_executesql @cmd, @ParamDef, @rtnVal OUTPUT
		SET @count = CAST(@rtnVal as int)

		IF @count > 0 BEGIN

			IF @deleteData = 'Y' BEGIN
			
				-- these records should be deleted
				IF @TableName IN ('vDDUL', 'vDDFL', 'vDDFLc') BEGIN
					SELECT @cmd = 'DELETE FROM ' + @TableName 
						+ ' WHERE ' + @ColName + ' = ' + CHAR(39) + @LookupName + CHAR(39)
				END
				ELSE BEGIN
					SELECT @cmd = 'UPDATE ' + @TableName 
						+ ' SET ' + @ColName + ' = NULL WHERE ' 
						+ @ColName + ' = ' + CHAR(39) + @LookupName + CHAR(39)
				END
				BEGIN TRY
					EXEC dbo.sp_executesql @cmd
				END TRY
				BEGIN CATCH
					SELECT @rc = ERROR_NUMBER()
					SET @errmsg = ERROR_MESSAGE()
					INSERT INTO #report (notes) VALUES ('EXCEPTION: ' + @errmsg)
					INSERT INTO #report (notes) VALUES ('UNABLE TO EXECUTE: ' + @cmd)
				END CATCH
				
				INSERT INTO #report (notes)
				VALUES ('EXECUTED: ' + @cmd + ' for ' + @rtnVal + ' records')
			END
			ELSE BEGIN
				IF @TableName IN (SELECT tablename FROM #formtables) BEGIN
					SELECT @cmd = 'SELECT DISTINCT ''WARNING: lookup found in ' + @TableName + '.' + @ColName + ' for Form = '' + Form FROM ' + @TableName + ' WHERE ' + @ColName + ' = ''' + @LookupName + ''''
					INSERT INTO #report
					EXEC dbo.sp_executesql @cmd
				END
				ELSE BEGIN
					INSERT INTO #report (notes)
					VALUES ('WARNING: lookup found in ' + @TableName + '.' + @ColName 
									+ ' ' + CAST(@count AS varchar(3)) + ' times')
				END
			END
		END
		ELSE
			-- if we want to "show all", show those table-column combinations
			-- that don't have any record for this SP
			IF @ShowAllTablesAndColumns = 'Y' BEGIN
				INSERT INTO #report (notes)
				VALUES ('Lookup found in ' + @TableName + '.' + @ColName + ' 0 times')
			END
		
		FETCH NEXT FROM DatabaseCursor INTO @TableName, @ColName
	END  
	CLOSE DatabaseCursor   
	DEALLOCATE DatabaseCursor 

	-------------------------------------------------------------------------------
	--
	--    Look in the descriptions of other stored procedures for the lookup's name
	--
	-------------------------------------------------------------------------------

	IF @SearchSchema = 'Y' BEGIN
		INSERT INTO #report (notes)
		SELECT SPECIFIC_NAME + ' (SPECIFIC_Name) exists in ROUTINE_NAME=' + ROUTINE_NAME
			+ '; do not delete'
		FROM INFORMATION_SCHEMA.ROUTINES
		WHERE ROUTINE_DEFINITION LIKE '%' + @LookupName + '%'
		and SPECIFIC_NAME <> @LookupName
	END
	
	END TRY
	BEGIN CATCH
		SELECT @rc = ERROR_NUMBER()
		SET @errmsg = ERROR_MESSAGE()
		INSERT INTO #report (notes)
		VALUES ('EXCEPTION: ' + @errmsg)
		GOTO REPORTIT
	END CATCH
END

REPORTIT:
	SET NOCOUNT OFF
	select * from #report
	RETURN @rc
GO
GRANT EXECUTE ON  [dbo].[vspDeleteLookupHelper] TO [public]
GO
