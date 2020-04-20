SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Francine Taylor
-- Create date: 10/4/2011
-- Description:
--    This is a procedure that should be run by anyone who wants to delete
--    an entire form.  First, the procedure should be run with default
--    values, to get a report of what needs to be done, and any warnings.
--
--    This report should be saved; once the data is deleted from the database
--    there is no way to retrieve your "todo" list.
--
--    The items on the list should be done after this SP is run with @deleteData = 'Y'.
--    Before deleting views or SPs, the corresponding delete procedure should
--    be run to make sure they aren't being used by any other forms.
-- =============================================
CREATE PROCEDURE [dbo].[vspDeleteDDFHHelper]
   (@deleteData char(1) = 'N', -- pass in Y if you want the DDFH data to be deleted
	@Form varchar(100),        -- name of the form to be deleted (from vDDFH.Form)
	@ShowAllTablesAndColumns char(1) = 'N', -- currently does nothing
	@SearchSchema char(1) = 'N', -- search through schema as well? currently not used
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
	DECLARE @count INT, @string1 varchar(500), @string2 varchar(500)
	DECLARE @ParamDef nvarchar(1000), @rtnVal nvarchar(1000)

	-- This is the table that produces the report output from this SP.
	IF EXISTS(SELECT * from tempdb..sysobjects where id = object_id('tempdb..#report') and type = 'U')
	BEGIN
	   DROP TABLE #report		/* if this isn't the first time this session */
	END
	create table #report (notes varchar(1000))

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
	   order by sysobjects.name DESC -- so we delete the 'c' tables first

	-- manipulate the order the records are deleted in.  There are some
	-- dependencies.
	DELETE FROM #formtables WHERE tablename IN ('vDDFH','vDDFHc','vDDFT','vDDFTc')
	INSERT INTO #formtables (tablename) VALUES ('vDDFT')
	INSERT INTO #formtables (tablename) VALUES ('vDDFTc')
	INSERT INTO #formtables (tablename) VALUES ('vDDFHc')
	INSERT INTO #formtables (tablename) VALUES ('vDDFH')
	
	IF EXISTS(SELECT * from tempdb..sysobjects where id = object_id('tempdb..#temp') and type = 'U')
	BEGIN
	   DROP TABLE #temp		/* if this isn't the first time this session */
	END
	create table #temp (tablename varchar(500))

	IF EXISTS(SELECT * from tempdb..sysobjects where id = object_id('tempdb..#temp2') and type = 'U')
	BEGIN
	   DROP TABLE #temp2		/* if this isn't the first time this session */
	END
	create table #temp2 (tablename varchar(500), colname varchar(500))

	-------------------------------------------------------------------------------
	--
	--    This section reports on various columns in the vDDFH record
	--
	-------------------------------------------------------------------------------

	IF (SELECT COUNT(*) FROM vDDFH WHERE [Form] = @Form) <> 1 BEGIN
		INSERT INTO #report (notes)
			VALUES ('WARNING: Did not find exactly one record in vDDFH for ' + @Form)
	END

	INSERT INTO #report (notes)
	SELECT 'May have to delete view for form: ' + ViewName
	FROM vDDFH WHERE Form = @Form and ViewName is not NULL

	INSERT INTO #report (notes)
	SELECT 'MANUAL: Remove form class ' + FormClassName + ' from the application'
	FROM vDDFH WHERE Form = @Form

	INSERT INTO #report (notes)
	SELECT 'May have to delete LoadProc:  ' + LoadProc
	FROM vDDFH WHERE Form = @Form and LoadProc is not NULL

	INSERT INTO #report (notes)
	SELECT 'May have to delete BatchProcessForm:  ' + BatchProcessForm
	FROM vDDFH WHERE Form = @Form and BatchProcessForm is not NULL

	-------------------------------------------------------------------------------
	--
	--    This section gets the help keywords for form and inputs
	--
	-------------------------------------------------------------------------------

	INSERT INTO #report (notes)
	SELECT 'Help keyword for form: ' + HelpKeyword
	FROM vDDFH WHERE Form = @Form and HelpKeyword is not NULL

	INSERT INTO #report (notes)
	SELECT 'Help keyword for input seq ' + CAST(Seq AS varchar(3)) + ' is ' + HelpKeyword
	FROM vDDFI WHERE Form = @Form and HelpKeyword is not NULL

	-------------------------------------------------------------------------------
	--
	--    This section checks for gridforms to be possibly deleted
	--
	-------------------------------------------------------------------------------

	INSERT INTO #report (notes)
	SELECT 'May have to remove secondary Grid Form: ' + GridForm
	FROM vDDFT WHERE Form = @Form and GridForm is not NULL

	-- check to make sure grid form is not used elsewhere
	INSERT INTO #report (notes)
	SELECT 'WARNING: Grid Form ' + GridForm + ' also used by ' + Form
	FROM vDDFT WHERE Form <> @Form and GridForm in
	   (SELECT GridForm FROM vDDFT WHERE Form = @Form and GridForm is not NULL)

	-------------------------------------------------------------------------------
	--
	--    This section checks for potential lookups to be deleted
	--
	-------------------------------------------------------------------------------

	INSERT INTO #report (notes)
	SELECT 'Lookup to potentially be deleted: ' + [Lookup]
	FROM vDDFL WHERE Form = @Form

	INSERT INTO #report (notes)
	SELECT 'Custom lookup to potentially be deleted: ' + [Lookup]
	FROM vDDFLc WHERE Form = @Form

	-------------------------------------------------------------------------------
	--
	--    This section checks for potential combo boxes to be deleted
	--
	-------------------------------------------------------------------------------

	INSERT INTO #report (notes)
	SELECT 'Combo box to potentially be deleted: ' + [ComboType] + ' (' + [Description] + ')'
	FROM vDDCB WHERE ComboType IN
	(SELECT ComboType FROM vDDFI WHERE Form = @Form and ComboType is not NULL)

	INSERT INTO #report (notes)
	SELECT 'Custom combo box to potentially be deleted: ' + [ComboType] + ' (' + [Description] + ')'
	FROM vDDCBc WHERE ComboType IN
	(SELECT ComboType FROM vDDFIc WHERE Form = @Form and ComboType is not NULL)

	-------------------------------------------------------------------------------
	--
	--    This section checks to see if there are any danger conditions in the
	--    validation SPs about to be deleted from DDFI
	--
	-------------------------------------------------------------------------------

	-- #temp will contain the names of all validation stored procedures used by
	--        the form that we are deleting
	--DELETE FROM #temp
	--INSERT INTO #temp (tablename) SELECT DISTINCT ValProc FROM vDDFI WHERE ValProc is not null and Form = @Form

	---- now run a list of all SPs to potentially be deleted
	--INSERT INTO #report (notes)
	--SELECT 'Validation SP to potentially be deleted: ' + tablename FROM #temp

	-- now run a list of all SPs to potentially be deleted
	INSERT INTO #report (notes)
	SELECT DISTINCT 'Validation SP to potentially be deleted: ' + ValProc
	FROM vDDFI WHERE ValProc is not null and Form = @Form
	
	-------------------------------------------------------------------------------
	--
	--    Look for reasons not to delete the form
	--
	-------------------------------------------------------------------------------

	-- this finds all tables with columns containing 'Form' as part of the name
	-- and checks for the form name
	DELETE FROM #temp2
	INSERT INTO #temp2 (tablename, colname)
	SELECT tablename=sysobjects.name, syscolumns.name
		FROM sysobjects 
		JOIN syscolumns ON sysobjects.id = syscolumns.id
		JOIN systypes ON syscolumns.xusertype=systypes.xusertype
	   WHERE sysobjects.xtype='U'
	   and syscolumns.name like '%Form%'
	   and syscolumns.name not like '%Format%'
	   and syscolumns.name <> 'Form'
	   and systypes.name = 'varchar'
	   and syscolumns.length > 10
	ORDER BY sysobjects.name,syscolumns.colid

    -----------------------------------------------------------------------
    ---------------------- special handling of tables ---------------------
	INSERT INTO #report (notes)
	SELECT 'WARNING: Form used in vDDFH as SecurityForm for form: ' + Form
	FROM vDDFH WHERE SecurityForm = @Form and Form <> @Form

	INSERT INTO #report (notes)
	SELECT 'WARNING: Form used in vDDFHc as SecurityForm for form: ' + Form
	FROM vDDFHc WHERE SecurityForm = @Form and Form <> @Form
	
	DELETE FROM #temp2 WHERE tablename = 'vDDFH' and colname = 'SecurityForm'
	-----------------------------------------------------------------------
	INSERT INTO #report (notes)
	SELECT 'ACTION: Delete bHQAT record for ' + KeyField
	FROM bHQAT WHERE FormName = @Form
	
	DELETE FROM #temp2 WHERE tablename = 'bHQAT'
	-----------------------------------------------------------------------
	
	DECLARE DatabaseCursor CURSOR FOR
	SELECT tablename, colname FROM #temp2

	OPEN DatabaseCursor

	FETCH NEXT FROM DatabaseCursor INTO @TableName, @ColName
	WHILE @@FETCH_STATUS = 0  
	BEGIN  

		-- todo: replace this list with a list of all tables containing 'Form'
		if @TableName in (select tablename from #formtables)
			set @string2 = ' for Form = ' + CHAR(39) + ' + Form'
		ELSE
			set @string2 = CHAR(39)

		-- these are tables for which the entire record will be deleted if a record
		-- containing the filename is found
		IF @ColName IN ('RelatedForm')
			set @string1 = CHAR(39) + 'ACTION1: Record will be deleted from ' 
						+ @TableName + ' for relation between form and '
						+ CHAR(39) + ' + Form '
		-- otherwise the value will just be set to NULL
		ELSE
			set @string1 = CHAR(39) + 'ACTION1: form name found in ' 
						+ @TableName + '.' + @ColName + ' will be set to NULL ' + @string2
		
		SELECT @cmd = 'SELECT ' + @string1 + ' FROM ' + @TableName
						+ ' WHERE [' + @ColName + '] = ' + CHAR(39) + @Form + CHAR(39)
		
		if @TableName in (select tablename from #formtables)
		set @cmd = @cmd + ' and Form <> ' + CHAR(39) + @Form + CHAR(39)

		BEGIN TRY
		INSERT INTO #report
			EXEC dbo.sp_executesql @cmd
		END TRY
		BEGIN CATCH
			SET @rc = 1
			INSERT INTO #report (notes)
			VALUES ('ERROR: Unable to execute: ' + @cmd)
		END CATCH

		-- for each table which contains a column with the word "Form" in it,
		-- remove records which contain the formname in @Form in that column.
		IF @deleteData = 'Y'
		BEGIN
			BEGIN TRY
	            
				IF @ColName IN ('RelatedForm')
        			SELECT @cmd = 'DELETE FROM ' + @TableName 
						+ ' WHERE [' + @ColName + '] = ' + CHAR(39) + @Form + CHAR(39)
				ELSE
					SELECT @cmd = 'UPDATE ' + @TableName 
						+ ' SET [' + @ColName + '] = NULL WHERE [' + @ColName + '] = '
						+ CHAR(39) + @Form + CHAR(39)
				
				EXECUTE sp_executesql @cmd
			END TRY
			BEGIN CATCH
				SET @rc = 1
				INSERT INTO #report (notes)
				VALUES ('ERROR: Unable to execute: ' + @cmd)
			END CATCH

		END

		FETCH NEXT FROM DatabaseCursor INTO @TableName, @ColName
	END  
	CLOSE DatabaseCursor   
	DEALLOCATE DatabaseCursor 

	-------------------------------------------------------------------------------
	--
	--    This section deletes all records from all tables containing the form
	--    value in their Form column
	--
	-------------------------------------------------------------------------------

	-- #formtables contains the names of all tables with the column Form

	-- move vDDFH to the end, since it will fail the first time through
	-- if the records for dependent tables haven't been deleted

	DECLARE DatabaseCursor CURSOR FOR
	SELECT tablename FROM #formtables

	OPEN DatabaseCursor

	FETCH NEXT FROM DatabaseCursor INTO @TableName  
	WHILE @@FETCH_STATUS = 0  
	BEGIN  

		SELECT @cmd = 'SELECT @rtnVal = COUNT(*) FROM ' + @TableName + ' WHERE Form = ' + CHAR(39) + @Form + CHAR(39)
		Select @ParamDef = '@rtnVal nvarchar(1000) OUTPUT'

		BEGIN TRY
			EXEC dbo.sp_executesql @cmd, @ParamDef, @rtnVal OUTPUT
		END TRY
		BEGIN CATCH
			SET @rc = 1
			INSERT INTO #report (notes)
			VALUES ('ERROR: Unable to execute: ' + @cmd)
		END CATCH
		
		IF CAST(@rtnVal as int) > 0
		BEGIN
			INSERT INTO #report (notes)
			VALUES ('ACTION2: ' + @rtnVal + ' will be deleted from ' + @TableName)
		END
	    
		IF @deleteData = 'Y'
		BEGIN
			BEGIN TRY
				SELECT @cmd = 'DELETE FROM ' + @TableName + ' WHERE Form = ''' + @Form + ''''
				EXEC sp_executesql @cmd
			END TRY
			BEGIN CATCH
				SET @rc = 2
				INSERT INTO #report (notes)
				VALUES ('ERROR: Unable to execute: ' + @cmd)
			END CATCH

		END

		FETCH NEXT FROM DatabaseCursor INTO @TableName  
	END  
	CLOSE DatabaseCursor   
	DEALLOCATE DatabaseCursor 
	
	IF @deleteData = 'Y' BEGIN
		DELETE FROM bHQAT WHERE FormName = @Form
	END
	
	END TRY
	BEGIN CATCH
		SELECT @rc = ERROR_NUMBER()
		SET @errmsg = ERROR_MESSAGE()
		INSERT INTO #report (notes)
		VALUES ('EXCEPTION: ' + @errmsg)
		GOTO REPORTIT
	END CATCH

REPORTIT:
	IF @deleteData = 'N'
		SET @string1 = ' will be'
	ELSE
		SET @string1 = ' was'
	IF @rc = 0
	BEGIN
		INSERT INTO #report (notes)
		VALUES ('RESULT: ' + @Form + @string1 + ' successfully deleted')
	END
	ELSE BEGIN
		INSERT INTO #report (notes)
		VALUES ('RESULT: ' + @Form + @string1 + ' NOT successfully deleted; ROLLBACK occurred')
	END

	SET NOCOUNT OFF
	select * from #report
	RETURN @rc
END
GO
GRANT EXECUTE ON  [dbo].[vspDeleteDDFHHelper] TO [public]
GO
