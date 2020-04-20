SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Francine Taylor
-- Create date: 10/4/2011
-- Description:
--    This is a procedure that should be run by anyone who wants to delete
--    a view.  If it is run with @deleteData = 'Y', all references to the view
--    will be deleted from the database.
-- =============================================
CREATE PROCEDURE [dbo].[vspDeleteViewHelper]
   (@deleteData char(1) = 'N', -- pass in Y if you want the view data to be deleted
	@ViewName varchar(100),        -- name of the view to be deleted
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

	-- This is the table that produces the report output from this View.
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
	--    Look for all tables which contain the names of the view
	--
	-------------------------------------------------------------------------------
	insert into #report (notes) values ('Deletion information for view: ' + @ViewName)
	set @todelete = 0
	
	-- this finds all tables with columns containing 'View' as part of the name
	-- and checks for the form name
	INSERT INTO #spcolumns (tablename, colname)
	SELECT tablename=sysobjects.name, syscolumns.name
		FROM sysobjects 
		JOIN syscolumns ON sysobjects.id = syscolumns.id
		JOIN systypes ON syscolumns.xusertype=systypes.xusertype
	   WHERE sysobjects.xtype='U'
	   and syscolumns.name like '%View%'
	   and systypes.name = 'varchar'
	   and syscolumns.length > 10
	ORDER BY sysobjects.name,syscolumns.colid
	
	DECLARE DatabaseCursor CURSOR FOR
	SELECT tablename, colname FROM #spcolumns

	OPEN DatabaseCursor

	FETCH NEXT FROM DatabaseCursor INTO @TableName, @ColName
	WHILE @@FETCH_STATUS = 0  
	BEGIN  

		-- are there any for this combination?
		SELECT @cmd = 'SELECT @rtnVal = COUNT(*) FROM ' + @TableName
						+ ' WHERE [' + @ColName + '] = ' + CHAR(39) + @ViewName + CHAR(39)
		Select @ParamDef = '@rtnVal nvarchar(1000) OUTPUT'
		EXEC dbo.sp_executesql @cmd, @ParamDef, @rtnVal OUTPUT
		SET @count = CAST(@rtnVal as int)

		IF @count > 0 BEGIN
			IF @TableName IN (SELECT tablename FROM #formtables) BEGIN
				SELECT @cmd = 'SELECT DISTINCT ''WARNING: View found in ' + @TableName + '.' + @ColName + ' for Form = '' + Form FROM ' + @TableName + ' WHERE ' + @ColName + ' = ''' + @ViewName + ''''
				INSERT INTO #report
				EXEC dbo.sp_executesql @cmd
			END
			ELSE BEGIN
			INSERT INTO #report (notes)
				VALUES ('View found in ' + @TableName + '.' + @ColName 
								+ ' ' + CAST(@count AS varchar(3)) + ' times')
			END
			set @todelete = @todelete + @count
			IF @deleteData = 'Y' BEGIN
				BEGIN TRY
					SELECT @cmd = 'UPDATE ' + @TableName + ' SET ' + @ColName
						+ ' = NULL WHERE ' + @ColName + ' = ' + CHAR(39) + @ViewName + CHAR(39)
					EXEC dbo.sp_executesql @cmd
				END TRY
				BEGIN CATCH
					SELECT @rc = ERROR_NUMBER()
					SET @errmsg = ERROR_MESSAGE()
					INSERT INTO #report (notes) VALUES ('EXCEPTION: Unable to execute' + @cmd)
					INSERT INTO #report (notes) VALUES ('EXCEPTION: ' + @errmsg)
				END CATCH
			END
		END
		ELSE
			-- if we want to "show all", show those table-column combinations
			-- that don't have any record for this SP
			IF @ShowAllTablesAndColumns = 'Y' BEGIN
				INSERT INTO #report (notes)
				VALUES ('View not found in ' + @TableName + '.' + @ColName)
			END
		
		FETCH NEXT FROM DatabaseCursor INTO @TableName, @ColName
	END  
	CLOSE DatabaseCursor   
	DEALLOCATE DatabaseCursor 

	-------------------------------------------------------------------------------
	--
	--    Look for triggers on the view
	--
	-------------------------------------------------------------------------------
	declare @reportcount int
	select @reportcount = COUNT(*) from #report
	
	insert into #report (notes) 
	SELECT 'Delete trigger: ' + t.name + '   (trigger.object_id = ' + cast(t.object_id as varchar(10)) + ')'
	FROM sys.triggers AS t     
      JOIN sys.views AS v ON t.parent_id = v.object_id
	WHERE v.name = @ViewName
	
	if (SELECT COUNT(*) from #report) > @reportcount BEGIN
		insert into #report (notes) 
			values ('MANUAL: For each trigger found, add a delete trigger instruction to the view drop script.')
		insert into #report (notes) 
			values ('MANUAL: Remember to delete the trigger script from Subversion.')
	END
	-------------------------------------------------------------------------------
	--
	--    Look in the decriptions of other stored procedures
	--
	-------------------------------------------------------------------------------

	IF @SearchSchema = 'Y' BEGIN
		INSERT INTO #report (notes)
		SELECT SPECIFIC_NAME + ' (SPECIFIC_Name) exists in ROUTINE_NAME=' + ROUTINE_NAME
			+ '; do not delete'
		FROM INFORMATION_SCHEMA.ROUTINES
		WHERE ROUTINE_DEFINITION LIKE '%' + @ViewName + '%'
		and SPECIFIC_NAME <> @ViewName
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
	if @todelete = 0
		insert into #report (notes) values ('View was not found in the database')

	SET NOCOUNT OFF
	select * from #report
	RETURN @rc
GO
GRANT EXECUTE ON  [dbo].[vspDeleteViewHelper] TO [public]
GO
