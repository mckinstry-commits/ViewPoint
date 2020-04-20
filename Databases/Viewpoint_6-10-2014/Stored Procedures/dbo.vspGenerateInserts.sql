SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create PROC [dbo].[vspGenerateInserts]
(
	@table_name varchar(776),  		-- The table/view for which the INSERT statements will be generated using the existing data
	@target_table varchar(776) = NULL, 	-- Use this parameter to specify a different table name into which the data will be inserted
	@include_column_list bit = 1,		-- Use this parameter to include/ommit column list in the generated INSERT statement
	@from varchar(800) = NULL, 		-- Use this parameter to filter the rows based on a filter condition (using WHERE)
	@where VARCHAR(MAX) = NULL,      -- The where clause
	@order_by VARCHAR(MAX) = NULL,   -- The order to extract data
	@include_timestamp bit = 0, 		-- Specify 1 for this parameter, if you want to include the TIMESTAMP/ROWVERSION column's data in the INSERT statement
	@debug_mode bit = 0,			-- If @debug_mode is set to 1, the SQL statements constructed by this procedure will be printed for later examination
	@owner varchar(64) = NULL,		-- Use this parameter if you are not the owner of the table
	@ommit_images bit = 0,			-- Use this parameter to generate INSERT statements by omitting the 'image' columns
	@ommit_identity bit = 0,		-- Use this parameter to ommit the identity columns
	@top int = NULL,			-- Use this parameter to generate INSERT statements only for the TOP n rows
	@cols_to_include varchar(8000) = NULL,	-- List of columns to be included in the INSERT statement
	@cols_to_exclude varchar(8000) = NULL,	-- List of columns to be excluded from the INSERT statement
	@disable_constraints bit = 0,		-- When 1, disables foreign key constraints and enables them after the INSERT statements
	@ommit_computed_cols bit = 0,		-- When 1, computed columns will not be included in the INSERT statement
	@disable_triggers BIT = 0,
	@delete_target BIT = 0,
	@OutputScript varchar(MAX) OUTPUT,
	@NumRows int OUTPUT
)
AS
BEGIN

/***********************************************************************************************************
NOTE:  This is heavily rewritten.  Namely we wanted to output the insert statement as a string
Modified:  JayR 10/18/2012
           JayR 2013-06-10 TFS-41459 Prep for inclusion in 6.7
		   JayR 2013-06-17 TFS-41459 Removed special character as it interfers with Gail's database compares. 

Procedure:	vspGenerateInserts  (Build 22) 
		(Copyright 2002 Narayana Vyas Kondreddi. All rights reserved.)
                                          
Purpose:	To generate INSERT statements from existing data. 
		These INSERTS can be executed to regenerate the data at some other location.
		This procedure is also useful to create a database setup, where in you can 
		script your data along with your table definitions.

Written by:	Narayana Vyas Kondreddi
	        http://vyaskn.tripod.com

Acknowledgements:
		Divya Kalra	-- For beta testing
		Mark Charsley	-- For reporting a problem with scripting uniqueidentifier columns with NULL values
		Artur Zeygman	-- For helping me simplify a bit of code for handling non-dbo owned tables
		Joris Laperre   -- For reporting a regression bug in handling text/ntext columns

Tested on: 	SQL Server 7.0 and SQL Server 2000

Date created:	January 17th 2001 21:52 GMT

Date modified:	May 1st 2002 19:50 GMT

Email: 		vyaskn@hotmail.com

NOTE:		This procedure may not work with tables with too many columns.
		Results can be unpredictable with huge text columns or SQL Server 2000's sql_variant data types
		Whenever possible, Use @include_column_list parameter to ommit column list in the INSERT statement, for better results
		IMPORTANT: This procedure is not tested with internation data (Extended characters or Unicode). If needed
		you might want to convert the datatypes of character variables in this procedure to their respective unicode counterparts
		like nchar and nvarchar
		

Example 1:	To generate INSERT statements for table 'titles':
		
		EXEC vspGenerateInserts 'titles'

Example 2: 	To ommit the column list in the INSERT statement: (Column list is included by default)
		IMPORTANT: If you have too many columns, you are advised to ommit column list, as shown below,
		to avoid erroneous results
		
		EXEC vspGenerateInserts 'titles', @include_column_list = 0

Example 3:	To generate INSERT statements for 'titlesCopy' table from 'titles' table:

		EXEC vspGenerateInserts 'titles', 'titlesCopy'

Example 4:	To generate INSERT statements for 'titles' table for only those titles 
		which contain the word 'Computer' in them:
		NOTE: Do not complicate the FROM or WHERE clause here. It's assumed that you are good with T-SQL if you are using this parameter

		EXEC vspGenerateInserts 'titles', @from = "from titles where title like '%Computer%'"

Example 5: 	To specify that you want to include TIMESTAMP column's data as well in the INSERT statement:
		(By default TIMESTAMP column's data is not scripted)

		EXEC vspGenerateInserts 'titles', @include_timestamp = 1

Example 6:	To print the debug information:
  
		EXEC vspGenerateInserts 'titles', @debug_mode = 1

Example 7: 	If you are not the owner of the table, use @owner parameter to specify the owner name
		To use this option, you must have SELECT permissions on that table

		EXEC vspGenerateInserts Nickstable, @owner = 'Nick'

Example 8: 	To generate INSERT statements for the rest of the columns excluding images
		When using this otion, DO NOT set @include_column_list parameter to 0.

		EXEC vspGenerateInserts imgtable, @ommit_images = 1

Example 9: 	To generate INSERT statements excluding (ommiting) IDENTITY columns:
		(By default IDENTITY columns are included in the INSERT statement)

		EXEC vspGenerateInserts mytable, @ommit_identity = 1

Example 10: 	To generate INSERT statements for the TOP 10 rows in the table:
		
		EXEC vspGenerateInserts mytable, @top = 10

Example 11: 	To generate INSERT statements with only those columns you want:
		
		EXEC vspGenerateInserts titles, @cols_to_include = "'title','title_id','au_id'"

Example 12: 	To generate INSERT statements by omitting certain columns:
		
		EXEC vspGenerateInserts titles, @cols_to_exclude = "'title','title_id','au_id'"

Example 13:	To avoid checking the foreign key constraints while loading data with INSERT statements:
		
		EXEC vspGenerateInserts titles, @disable_constraints = 1

Example 14: 	To exclude computed columns from the INSERT statement:
		EXEC vspGenerateInserts MyTable, @ommit_computed_cols = 1
***********************************************************************************************************/

SET NOCOUNT ON

--Making sure user only uses either @cols_to_include or @cols_to_exclude
IF ((@cols_to_include IS NOT NULL) AND (@cols_to_exclude IS NOT NULL))
	BEGIN
		RAISERROR('Use either @cols_to_include or @cols_to_exclude. Do not use both the parameters at once',16,1)
		RETURN -1 --Failure. Reason: Both @cols_to_include and @cols_to_exclude parameters are specified
	END

--Making sure the @cols_to_include and @cols_to_exclude parameters are receiving values in proper format
IF ((@cols_to_include IS NOT NULL) AND (PATINDEX('''%''',@cols_to_include) = 0))
	BEGIN
		RAISERROR('Invalid use of @cols_to_include property',16,1)
		PRINT 'Specify column names surrounded by single quotes and separated by commas'
		PRINT 'Eg: EXEC vspGenerateInserts titles, @cols_to_include = "''title_id'',''title''"'
		RETURN -1 --Failure. Reason: Invalid use of @cols_to_include property
	END

IF ((@cols_to_exclude IS NOT NULL) AND (PATINDEX('''%''',@cols_to_exclude) = 0))
	BEGIN
		RAISERROR('Invalid use of @cols_to_exclude property',16,1)
		PRINT 'Specify column names surrounded by single quotes and separated by commas'
		PRINT 'Eg: EXEC vspGenerateInserts titles, @cols_to_exclude = "''title_id'',''title''"'
		RETURN -1 --Failure. Reason: Invalid use of @cols_to_exclude property
	END


--Checking to see if the database name is specified along wih the table name
--Your database context should be local to the table for which you want to generate INSERT statements
--specifying the database name is not allowed
IF (PARSENAME(@table_name,3)) IS NOT NULL
	BEGIN
		RAISERROR('Do not specify the database name. Be in the required database and just specify the table name.',16,1)
		RETURN -1 --Failure. Reason: Database name is specified along with the table name, which is not allowed
	END

--Checking for the existence of 'user table' or 'view'
--This procedure is not written to work on system tables
--To script the data in system tables, just create a view on the system tables and script the view instead

IF @owner IS NULL
	BEGIN
		IF ((OBJECT_ID(@table_name,'U') IS NULL) AND (OBJECT_ID(@table_name,'V') IS NULL)) 
			BEGIN
				RAISERROR('User table or view not found.',16,1)
				PRINT 'You may see this error, if you are not the owner of this table or view. In that case use @owner parameter to specify the owner name.'
				PRINT 'Make sure you have SELECT permission on that table or view.'
				RETURN -1 --Failure. Reason: There is no user table or view with this name
			END
	END
ELSE
	BEGIN
		IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME = @table_name AND (TABLE_TYPE = 'BASE TABLE' OR TABLE_TYPE = 'VIEW') AND TABLE_SCHEMA = @owner)
			BEGIN
				RAISERROR('User table or view not found.',16,1)
				PRINT 'You may see this error, if you are not the owner of this table. In that case use @owner parameter to specify the owner name.'
				PRINT 'Make sure you have SELECT permission on that table or view.'
				RETURN -1 --Failure. Reason: There is no user table or view with this name		
			END
	END

--Variable declarations
DECLARE		@Column_ID int, 		
		@Column_List varchar(8000), 
		@Column_Name varchar(128), 
		@Start_Insert varchar(786), 
		@Data_Type varchar(128), 
		@Actual_Values NVARCHAR(MAX),	--This is the string that will be finally executed to generate INSERT statements
		--@OutputScript VARCHAR(MAX),
		@LineTerm VARCHAR(10),
		@IDN varchar(128),		--Will contain the IDENTITY column's name in the table
		@insertRow VARCHAR(MAX),
		--@bolHasData BIT,
		@FileLineTerm VARCHAR(100),
		@FromWhereOrder VARCHAR(MAX),
		@curInsertData CURSOR

--Variable Initialization
SET @IDN = '';
SET @Column_ID = 0;
SET @Column_Name = '';
SET @Column_List = '';
SET @Actual_Values = '';
SET @OutputScript = '';
SET @LineTerm = CHAR(13) + CHAR(10);
SET @FileLineTerm = ' + CHAR(13) + CHAR(10) ';
SET @NumRows = 0;

IF LTRIM(RTRIM(ISNULL(@where,''))) <> '' AND CHARINDEX('WHERE',UPPER(@where),1) <= 0
	BEGIN
		SET @where = ' WHERE ' + @where;
	END

IF LTRIM(RTRIM(ISNULL(@from,''))) <> '' AND CHARINDEX('FROM',UPPER(@from),1) <= 0
	BEGIN
		SET @from = ' FROM ' + @from;
	END

SET @FromWhereOrder = COALESCE(@from,' FROM ' + CASE WHEN @owner IS NULL THEN '' ELSE '[' + LTRIM(RTRIM(@owner)) + '].' END + '[' + rtrim(@table_name) + ']' + '(NOLOCK)') 
+ ' ' + ISNULL(@where,'') 
+ ' ' + ISNULL(@order_by,'');

IF @owner IS NULL 
	BEGIN
		SET @Start_Insert = 'INSERT INTO ' + '[' + RTRIM(COALESCE(@target_table,@table_name)) + ']' 
	END
ELSE
	BEGIN
		SET @Start_Insert = 'INSERT ' + '[' + LTRIM(RTRIM(@owner)) + '].' + '[' + RTRIM(COALESCE(@target_table,@table_name)) + ']' 		
	END


--To get the first column's ID

SELECT	@Column_ID = MIN(ORDINAL_POSITION) 	
FROM	INFORMATION_SCHEMA.COLUMNS (NOLOCK) 
WHERE 	TABLE_NAME = @table_name AND
(@owner IS NULL OR TABLE_SCHEMA = @owner)

--Loop through all the columns of the table, to get the column names and their data types
WHILE @Column_ID IS NOT NULL
	BEGIN
		SELECT 	@Column_Name = QUOTENAME(COLUMN_NAME), 
		@Data_Type = DATA_TYPE 
		FROM 	INFORMATION_SCHEMA.COLUMNS (NOLOCK) 
		WHERE 	ORDINAL_POSITION = @Column_ID AND 
		TABLE_NAME = @table_name AND
		(@owner IS NULL OR TABLE_SCHEMA = @owner)

		IF @cols_to_include IS NOT NULL --Selecting only user specified columns
		BEGIN
			IF CHARINDEX( '''' + SUBSTRING(@Column_Name,2,LEN(@Column_Name)-2) + '''',@cols_to_include) = 0 
			BEGIN
				GOTO SKIP_LOOP
			END
		END

		IF @cols_to_exclude IS NOT NULL --Selecting only user specified columns
		BEGIN
			IF CHARINDEX( '''' + SUBSTRING(@Column_Name,2,LEN(@Column_Name)-2) + '''',@cols_to_exclude) <> 0 
			BEGIN
				GOTO SKIP_LOOP
			END
		END

		--Making sure to output SET IDENTITY_INSERT ON/OFF in case the table has an IDENTITY column
		IF (SELECT COLUMNPROPERTY( OBJECT_ID(QUOTENAME(COALESCE(@owner,USER_NAME())) + '.' + @table_name),SUBSTRING(@Column_Name,2,LEN(@Column_Name) - 2),'IsIdentity')) = 1 
		BEGIN
			IF @ommit_identity = 0 --Determing whether to include or exclude the IDENTITY column
				SET @IDN = @Column_Name
			ELSE
				GOTO SKIP_LOOP			
		END
		
		--Making sure whether to output computed columns or not
		IF @ommit_computed_cols = 1
		BEGIN
			IF (SELECT COLUMNPROPERTY( OBJECT_ID(QUOTENAME(COALESCE(@owner,USER_NAME())) + '.' + @table_name),SUBSTRING(@Column_Name,2,LEN(@Column_Name) - 2),'IsComputed')) = 1 
			BEGIN
				GOTO SKIP_LOOP					
			END
		END
		
		--Tables with columns of IMAGE data type are not supported for obvious reasons
		IF(@Data_Type in ('image'))
			BEGIN
				IF (@ommit_images = 0)
					BEGIN
						RAISERROR('Tables with image columns are not supported.',16,1)
						PRINT 'Use @ommit_images = 1 parameter to generate INSERTs for the rest of the columns.'
						PRINT 'DO NOT ommit Column List in the INSERT statements. If you ommit column list using @include_column_list=0, the generated INSERTs will fail.'
						RETURN -1 --Failure. Reason: There is a column with image data type
					END
				ELSE
					BEGIN
					GOTO SKIP_LOOP
					END
			END

		--Determining the data type of the column and depending on the data type, the VALUES part of
		--the INSERT statement is generated. Care is taken to handle columns with NULL values. Also
		--making sure, not to lose any data from flot, real, money, smallmomey, datetime columns
		SET @Actual_Values = @Actual_Values  +
		CASE 
			WHEN @Data_Type IN ('char','varchar','nchar','nvarchar') 
				THEN 
					'COALESCE('''''''' + REPLACE(RTRIM(' + @Column_Name + '),'''''''','''''''''''')+'''''''',''NULL'')'
			WHEN @Data_Type IN ('datetime','smalldatetime') 
				THEN 
					'COALESCE('''''''' + RTRIM(CONVERT(char,' + @Column_Name + ',109))+'''''''',''NULL'')'
			WHEN @Data_Type IN ('uniqueidentifier') 
				THEN  
					'COALESCE('''''''' + REPLACE(CONVERT(char(255),RTRIM(' + @Column_Name + ')),'''''''','''''''''''')+'''''''',''NULL'')'
			WHEN @Data_Type IN ('text','ntext') 
				THEN  
					'COALESCE('''''''' + REPLACE(CONVERT(char(8000),' + @Column_Name + '),'''''''','''''''''''')+'''''''',''NULL'')'					
			WHEN @Data_Type IN ('binary','varbinary') 
				THEN  
					'COALESCE(RTRIM(CONVERT(char,' + 'CONVERT(int,' + @Column_Name + '))),''NULL'')'  
			WHEN @Data_Type IN ('timestamp','rowversion') 
				THEN  
					CASE 
						WHEN @include_timestamp = 0 
							THEN 
								'''DEFAULT''' 
							ELSE 
								'COALESCE(RTRIM(CONVERT(char,' + 'CONVERT(int,' + @Column_Name + '))),''NULL'')'  
					END
			WHEN @Data_Type IN ('float','real','money','smallmoney')
				THEN
					'COALESCE(LTRIM(RTRIM(' + 'CONVERT(char, ' +  @Column_Name  + ',2)' + ')),''NULL'')' 
			ELSE 
				'COALESCE(LTRIM(RTRIM(' + 'CONVERT(char, ' +  @Column_Name  + ')' + ')),''NULL'')' 
		END   + '+' +  ''',''' + ' + '
		
		--Generating the column list for the INSERT statement
		SET @Column_List = @Column_List +  @Column_Name + ','	

		SKIP_LOOP: --The label used in GOTO

		SELECT 	@Column_ID = MIN(ORDINAL_POSITION) 
		FROM 	INFORMATION_SCHEMA.COLUMNS (NOLOCK) 
		WHERE 	TABLE_NAME = @table_name AND 
		ORDINAL_POSITION > @Column_ID AND
		(@owner IS NULL OR TABLE_SCHEMA = @owner)

	--Loop ends here!
	END

--To get rid of the extra characters that got concatenated during the last run through the loop
SET @Column_List = LEFT(@Column_List,len(@Column_List) - 1)
SET @Actual_Values = LEFT(@Actual_Values,len(@Actual_Values) - 6)

IF LTRIM(@Column_List) = '' 
	BEGIN
		RAISERROR('No columns to select. There should at least be one column to generate the output',16,1)
		RETURN -1 --Failure. Reason: Looks like all the columns are ommitted using the @cols_to_exclude parameter
	END

--Forming the final string that will be executed, to output the INSERT statements
IF (@include_column_list <> 0)
	BEGIN
		SET @Actual_Values = 
			'SELECT ' +  
			CASE WHEN @top IS NULL OR @top < 0 THEN '' ELSE ' TOP ' + LTRIM(STR(@top)) + ' ' END + 
			'''' + RTRIM(@Start_Insert) + 
			' ''+' + '''(' + RTRIM(@Column_List) +  '''+' + ''')''' + 
			' +''VALUES(''+ ' +  @Actual_Values  + '+'')''' + ' ' + @FileLineTerm + ' colInsertData ' +
			@FromWhereOrder;
			--COALESCE(@from + ' ' + ISNULL(@where,''),' FROM ' + CASE WHEN @owner IS NULL THEN '' ELSE '[' + LTRIM(RTRIM(@owner)) + '].' END + '[' + rtrim(@table_name) + ']' + '(NOLOCK)')
	END
ELSE IF (@include_column_list = 0)
	BEGIN
		SET @Actual_Values = 
			'SELECT ' + 
			CASE WHEN @top IS NULL OR @top < 0 THEN '' ELSE ' TOP ' + LTRIM(STR(@top)) + ' ' END + 
			'''' + RTRIM(@Start_Insert) + 
			' '' +''VALUES(''+ ' +  @Actual_Values + '+'')''' + ' ' + @FileLineTerm + ' colInsertData ' +
			@FromWhereOrder;
			--COALESCE(@from + ' ' + ISNULL(@where,''),' FROM ' + CASE WHEN @owner IS NULL THEN '' ELSE '[' + LTRIM(RTRIM(@owner)) + '].' END + '[' + rtrim(@table_name) + ']' + '(NOLOCK)')
	END	

--Determining whether to ouput any debug information
IF @debug_mode =1
	BEGIN
		SET @OutputScript = @OutputScript + @LineTerm + '/*****START OF DEBUG INFORMATION*****'
		SET @OutputScript = @OutputScript + @LineTerm + 'Beginning of the INSERT statement:'
		SET @OutputScript = @OutputScript + @LineTerm + @Start_Insert
		SET @OutputScript = @OutputScript + @LineTerm + ''
		SET @OutputScript = @OutputScript + @LineTerm + 'The column list:'
		SET @OutputScript = @OutputScript + @LineTerm + @Column_List
		SET @OutputScript = @OutputScript + @LineTerm + ''
		SET @OutputScript = @OutputScript + @LineTerm + 'The SELECT statement executed to generate the INSERTs'
		SET @OutputScript = @OutputScript + @LineTerm + @Actual_Values
		SET @OutputScript = @OutputScript + @LineTerm + ''
		SET @OutputScript = @OutputScript + @LineTerm + '*****END OF DEBUG INFORMATION*****/'
		SET @OutputScript = @OutputScript + @LineTerm + ''
		
		SET @OutputScript = @OutputScript + @LineTerm + '--INSERTs generated by ''vspGenerateInserts'' stored procedure written by Vyas'
		SET @OutputScript = @OutputScript + @LineTerm + '--Build number: 22'
		SET @OutputScript = @OutputScript + @LineTerm + '--Problems/Suggestions? Contact Vyas @ vyaskn@hotmail.com'
		SET @OutputScript = @OutputScript + @LineTerm + '--http://vyaskn.tripod.com'	
	END

--SET @OutputScript = @OutputScript + @LineTerm + 'SET NOCOUNT ON' + @LineTerm;
SET @OutputScript = @OutputScript + @LineTerm;

--SET @OutputScript = @OutputScript + @LineTerm + '-- ''Inserting values into ' + '[' + RTRIM(COALESCE(@target_table,@table_name)) + ']' + ''''
SET @OutputScript = @OutputScript + '-- [' + RTRIM(COALESCE(@target_table,@table_name)) + ']' + @LineTerm;

--SET @OutputScript = @OutputScript + ' BEGIN TRY ' + @LineTerm;

--Determining whether to print IDENTITY_INSERT or not
IF (@IDN <> '')
	BEGIN
		SET @OutputScript = @OutputScript + 'SET IDENTITY_INSERT ' + QUOTENAME(COALESCE(@owner,USER_NAME())) + '.' + QUOTENAME(@table_name) + ' ON;' + @LineTerm
		--SET @OutputScript = @OutputScript + @LineTerm + 'GO'
	END

IF @disable_triggers = 1 
	BEGIN
		IF @owner IS NULL
			BEGIN
				SELECT 	@OutputScript = @OutputScript + 'ALTER TABLE ' + QUOTENAME(COALESCE(@target_table, @table_name)) + ' DISABLE TRIGGER ALL; ' + @LineTerm;
			END
		ELSE
			BEGIN
				SELECT 	@OutputScript = @OutputScript + 'ALTER TABLE ' + QUOTENAME(@owner) + '.' + QUOTENAME(COALESCE(@target_table, @table_name)) + ' DISABLE TRIGGER ALL; ' + @LineTerm;
			END

		--SET @OutputScript = @OutputScript + @LineTerm + 'GO'
	END

IF @disable_constraints = 1 AND (OBJECT_ID(QUOTENAME(COALESCE(@owner,USER_NAME())) + '.' + @table_name, 'U') IS NOT NULL)
	BEGIN
		IF @owner IS NULL
			BEGIN
				SELECT 	@OutputScript = @OutputScript + 'ALTER TABLE ' + QUOTENAME(COALESCE(@target_table, @table_name)) + ' NOCHECK CONSTRAINT ALL;' + @LineTerm --AS '--Code to disable constraints temporarily'
			END
		ELSE
			BEGIN
				SELECT 	@OutputScript = @OutputScript + 'ALTER TABLE ' + QUOTENAME(@owner) + '.' + QUOTENAME(COALESCE(@target_table, @table_name)) + ' NOCHECK CONSTRAINT ALL;' + @LineTerm --AS '--Code to disable constraints temporarily'
			END

		--SET @OutputScript = @OutputScript + @LineTerm + 'GO'
	END

IF @delete_target = 1 AND (OBJECT_ID(QUOTENAME(COALESCE(@owner,USER_NAME())) + '.' + @table_name, 'U') IS NOT NULL)
	BEGIN
		IF @owner IS NULL
			BEGIN
				SELECT 	@OutputScript = @OutputScript + 'DELETE FROM ' + QUOTENAME(COALESCE(@target_table, @table_name)) + ' ' + ISNULL(@where,'') + @LineTerm
			END
		ELSE
			BEGIN
				SELECT 	@OutputScript = @OutputScript + 'DELETE FROM ' + QUOTENAME(@owner) + '.' + QUOTENAME(COALESCE(@target_table, @table_name)) + ' ' + ISNULL(@where,'') + @LineTerm
			END

		--SET @OutputScript = @OutputScript + @LineTerm + 'GO'
	END

--All the hard work pays off here!!! You'll get your INSERT statements, when the next line executes!
--EXEC (@Actual_Values)
--SELECT @Actual_Values
--SET @OutputScript = @OutputScript + @LineTerm + @Actual_Values
SET @Actual_Values = N'SET @curInsertData = CURSOR FAST_FORWARD FOR ' + @Actual_Values + '; OPEN @curInsertData; ';

--SET @OutputScript = @OutputScript + @LineTerm + @Actual_Values;

EXECUTE sp_executesql @Actual_Values, N'@curInsertData CURSOR OUTPUT', @curInsertData = @curInsertData OUTPUT 

FETCH NEXT FROM @curInsertData INTO @insertRow
WHILE (@@FETCH_STATUS = 0)
BEGIN
	SET @NumRows = @NumRows + 1;
	SET @OutputScript = @OutputScript + @insertRow;
	FETCH NEXT FROM @curInsertData INTO @insertRow;
END
CLOSE @curInsertData;
DEALLOCATE @curInsertData;

--SET @OutputScript = @OutputScript + ' END TRY ' + @LineTerm;
--SET @OutputScript = @OutputScript + ' BEGIN CATCH ' + @LineTerm;

IF @disable_triggers = 1 AND (OBJECT_ID(QUOTENAME(COALESCE(@owner,USER_NAME())) + '.' + @table_name, 'U') IS NOT NULL)
	BEGIN
		IF @owner IS NULL
			BEGIN
				SET @OutputScript = @OutputScript + 'ALTER TABLE ' + QUOTENAME(COALESCE(@target_table, @table_name)) + ' ENABLE TRIGGER ALL ' + @LineTerm -- AS '--Code to enable the previously disabled constraints'			
			END
		ELSE
			BEGIN
				SET @OutputScript = @OutputScript + @LineTerm +	'ALTER TABLE ' + QUOTENAME(@owner) + '.' + QUOTENAME(COALESCE(@target_table, @table_name)) + '  ENABLE TRIGGER ALL '  + @LineTerm -- AS '--Code to enable the previously disabled constraints'
			END

		--SET @OutputScript = @OutputScript + @LineTerm + 'GO' + @LineTerm
	END
	
IF @disable_constraints = 1 AND (OBJECT_ID(QUOTENAME(COALESCE(@owner,USER_NAME())) + '.' + @table_name, 'U') IS NOT NULL)
	BEGIN
		IF @owner IS NULL
			BEGIN
				SET @OutputScript = @OutputScript + 'ALTER TABLE ' + QUOTENAME(COALESCE(@target_table, @table_name)) + ' CHECK CONSTRAINT ALL'  + @LineTerm -- AS '--Code to enable the previously disabled constraints'			
			END
		ELSE
			BEGIN
				SET @OutputScript = @OutputScript +	'ALTER TABLE ' + QUOTENAME(@owner) + '.' + QUOTENAME(COALESCE(@target_table, @table_name)) + ' CHECK CONSTRAINT ALL'  + @LineTerm -- AS '--Code to enable the previously disabled constraints'
			END

		--SET @OutputScript = @OutputScript + @LineTerm + 'GO' + @LineTerm
	END

--PRINT ''
IF (@IDN <> '')
	BEGIN
		SET @OutputScript = @OutputScript + 'SET IDENTITY_INSERT ' + QUOTENAME(COALESCE(@owner,USER_NAME())) + '.' + QUOTENAME(@table_name) + ' OFF;'  + @LineTerm
		--SET @OutputScript = @OutputScript + @LineTerm + 'GO'
	END

--SET @OutputScript = @OutputScript + ' END CATCH ' + @LineTerm;
SET @OutputScript = @OutputScript + @LineTerm; 

SET NOCOUNT OFF
--IF @NumRows = 0
--BEGIN
--	SET @OutputScript = '-- Table:' + @table_name + ' no data' + @LineTerm;
--END
--ELSE
--BEGIN
--	SELECT '-- Table:' + @table_name + ' no data' + @LineTerm;
--END 
END






GO
GRANT EXECUTE ON  [dbo].[vspGenerateInserts] TO [public]
GO