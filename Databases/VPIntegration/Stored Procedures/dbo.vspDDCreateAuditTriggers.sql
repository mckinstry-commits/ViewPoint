SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspDDCreateAuditTriggers]
/***********************************************************************
*	Created by: 	CC 05/07/2009 - Stored procedure to automatically generate audit triggers
*	Checked by:		JonathanP 5/22/2009
* 
*	Altered by:		CC 10/20/2009 - Correct issue with columns starting with numbers
*					CC 05/19/2010 - issue #139616 Correct issue in update trigger join using ISNULL causing conversion errors
*									on numeric columns, replaced with expanded IS NULL / IS NOT NULL logic
*					CC 05/20/2010 - issue #139615 - improve error returned by trigger
*					CG 12/09/2010 - Issue #140507 - Changed to no longer require column named "KeyID" to indicate identity column
*							
*	Usage:			TableName is the name of the table to create the triggers on,
* 					KeyColumnList is a comma delimited list of columns that reflect the form key value
*					
* 
***********************************************************************/
	  @TableName NVARCHAR(128) = NULL
	, @KeyNameList NVARCHAR(MAX) = NULL
	, @KeyColumnList NVARCHAR(MAX) = NULL
	, @CompanyColumn NVARCHAR(128) = NULL
	WITH EXECUTE AS 'viewpointcs'

AS  
BEGIN
	SET NOCOUNT ON;

	-----Initial Validation----
	IF @TableName IS NULL
		RAISERROR(N'@TableName parameter cannot be null.', 16, 1);

	IF @KeyNameList IS NULL
		RAISERROR(N'@KeyNameList parameter cannot be null.', 16, 1);

	IF @KeyColumnList IS NULL
		RAISERROR(N'@KeyColumnList parameter cannot be null.', 16, 1);

	-----Setup----------------

	DECLARE 
		  @SQL								NVARCHAR(MAX)
		, @ColumnName						NVARCHAR(128)
		, @SchemaName						NCHAR(3)
		, @InsertTriggerName				NVARCHAR(128)
		, @UpdateTriggerName				NVARCHAR(128)
		, @DeleteTriggerName				NVARCHAR(128)
		, @NewLine							NCHAR(2)
		, @Quote							NCHAR(1)
		, @KeyString						NVARCHAR(MAX)
		, @Seperator						NCHAR(3)
		, @KeyStringTerminator				NCHAR(3)
		, @JoinClause						NVARCHAR(MAX)
		, @JoinConcatination				NCHAR(5)
		, @UseFormKeyJoin					bYN
		, @TableVariableStatement			NVARCHAR(512)
		, @OutputClause						NVARCHAR(MAX)
		, @HQSAInsertStatement				NVARCHAR(MAX)
		, @HQSAInsertForDeleteStatement		NVARCHAR(MAX)
		, @CleanTableVariableStatement		NVARCHAR(256)
		, @TabStops							nvarchar(256)
		, @TabStopsP1						nvarchar(256)
		, @AuditCompanyString				nvarchar(MAX)
	   ;

	DECLARE @KeyNames TABLE 
				(
					  KeyName VARCHAR(150)
					, ItemNumber int
				);

	DECLARE @KeyColumns TABLE 
				(
					  KeyColumn VARCHAR(150)
					, ItemNumber int
				);

	SET @SchemaName = N'dbo';
	SELECT	  
			  @InsertTriggerName = @SchemaName + N'.vt' + @TableName + N'_Audit_Insert'
			, @UpdateTriggerName = @SchemaName + N'.vt' + @TableName + N'_Audit_Update'
			, @DeleteTriggerName = @SchemaName + N'.vt' + @TableName + N'_Audit_Delete'
			, @NewLine = Char(13) + Char(10)
			, @Quote = N''''
			, @KeyString = N'''<KeyString '
			, @Seperator = N' , '
			, @KeyStringTerminator = N'/>'''
			, @JoinConcatination = N' AND '
			, @UseFormKeyJoin = 'N' --Debugging/internal use			
			, @OutputClause = N''	
			, @TableVariableStatement = N''
			, @HQSAInsertStatement = N''
			, @HQSAInsertForDeleteStatement = N''
			, @CleanTableVariableStatement = N''
			, @TabStops =	CHAR(9)+ CHAR(9)+ CHAR(9)+ CHAR(9)+ CHAR(9)+ CHAR(9)+ CHAR(9)
			;
	SET @TabStopsP1 = @TabStops + CHAR(9)	
	-- Get the identity column of the table
	declare @identityColumn varchar(128)
	exec vspDDGetIdentityColumn @TableName, @identityColumn OUTPUT
	
	 ---------Build key string & join string--------------
	INSERT INTO @KeyNames
	SELECT Names, ItemNumber 
	FROM dbo.vfNumberedTableFromArray(@KeyNameList);

	INSERT INTO @KeyColumns
	SELECT Names, ItemNumber 
	FROM dbo.vfNumberedTableFromArray(@KeyColumnList);

	IF (SELECT MAX(ItemNumber) FROM @KeyNames) <> (SELECT MAX(ItemNumber) FROM @KeyColumns) 
		RAISERROR(N'Number of key column names does not match number of key columns.', 16, 1);
			
	SELECT @KeyString = @KeyString + KeyName + N' = "' + @Quote 
						+ N' + REPLACE(CAST(inserted.' + QUOTENAME(KeyColumn) + N' AS VARCHAR(MAX)),''"'', ''&quot;'') + ' + @Quote + N'" ' 
						
	FROM @KeyNames AS KeyNames
		INNER JOIN @KeyColumns AS KeyColumns ON KeyNames.ItemNumber = KeyColumns.ItemNumber;
		
	SELECT @KeyString = @KeyString + @KeyStringTerminator;

	-- if we have an identity use it				
	IF @identityColumn IS NOT NULL
	BEGIN
		SET @JoinClause = N' inserted.[' + @identityColumn + '] = deleted.[' + @identityColumn + '] ';
	END
	ELSE
	BEGIN
		SET @JoinClause = N'';			
		
		SELECT @JoinClause = @JoinClause + ' inserted.' + QUOTENAME(KeyColumn) + ' = deleted.' + QUOTENAME(KeyColumn) + ' ' + @JoinConcatination
		FROM @KeyColumns;

		SELECT @JoinClause = LEFT(@JoinClause, LEN(@JoinClause) - LEN(@JoinConcatination));
	END	
	
	---------Build Output Clauses & HQSA Insert------------
	--Only required if there are securable datatypes on the table
	IF EXISTS(	SELECT TOP 1 1 
				FROM DDSLShared
				WHERE TableName = @TableName
			 )
	BEGIN
	-- Use this commented section when adding FKeyID back to HQMA
	--	SELECT	  @TableVariableStatement = N'DECLARE @HQMAKeys TABLE
	--(
	--	  AuditID	bigint
	--	, FKeyID	bigint
	--);'
		SELECT	  @TableVariableStatement = N'DECLARE @HQMAKeys TABLE
	(
		  AuditID		bigint
		, KeyString		varchar(max)
	);'
				, @OutputClause = N'		OUTPUT inserted.AuditID, inserted.KeyString INTO @HQMAKeys (AuditID, KeyString) '
				--Clean is only necessary for the update trigger
				, @CleanTableVariableStatement = N' DELETE FROM @HQMAKeys; '
				;
		SELECT
		--Use commented lines when FKeyID is added to HQMA instead of key string
				@HQSAInsertStatement = @HQSAInsertStatement + ' INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT DISTINCT Keys.AuditID, ' + @Quote + DDSLShared.Datatype + @Quote + ', i.'+ DDSLShared.QualifierColumn 
				+ CASE 
					WHEN DDDTShared.InputType <> 1 AND DDDTShared.InputType <> 6 THEN ', i.' + DDSLShared.InstanceColumn 
					ELSE ', CAST(i.' + DDSLShared.InstanceColumn +' AS VARCHAR(30))'
				  END
				+ ', ' + @Quote + @TableName + @Quote + '
				FROM inserted AS i
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = ' + REPLACE(@KeyString,'inserted.', 'i.') + @NewLine --i.KeyID = Keys.FKeyID ' + @NewLine
				,
				@HQSAInsertForDeleteStatement = @HQSAInsertForDeleteStatement + ' INSERT INTO HQSA ( AuditID, Datatype, Qualifier, Instance, TableName)
				SELECT DISTINCT Keys.AuditID, ' + @Quote + DDSLShared.Datatype + @Quote + ', d.'+ DDSLShared.QualifierColumn 
				+ CASE 
					WHEN DDDTShared.InputType <> 1 AND DDDTShared.InputType <> 6 THEN ', d.' + DDSLShared.InstanceColumn 
					ELSE ', CAST(d.' + DDSLShared.InstanceColumn +' AS VARCHAR(30))'
				  END
				+ ', ' + @Quote + @TableName + @Quote + '
				FROM deleted AS d
				INNER JOIN @HQMAKeys AS Keys ON Keys.KeyString = ' + REPLACE(@KeyString, 'inserted.', 'd.') + @NewLine --d.KeyID = Keys.FKeyID ' + @NewLine
				FROM DDSLShared
				INNER JOIN DDDTShared ON DDSLShared.Datatype = DDDTShared.Datatype
				WHERE TableName = @TableName
	END
	------------------------------------------------------

	----------Drop existing triggers----------------------
		SET @SQL =	N'IF (OBJECT_ID(' + @Quote + @InsertTriggerName + @Quote + N', ''TR'') IS NOT NULL)' + @NewLine
					+ N'	DROP TRIGGER ' + @InsertTriggerName;
		--PRINT (@SQL)
		EXEC (@SQL);

		SET @SQL =	N'IF (OBJECT_ID(' + @Quote + @UpdateTriggerName + @Quote + N', ''TR'') IS NOT NULL)' + @NewLine	   
					+ N'	DROP TRIGGER ' + @UpdateTriggerName;
		--PRINT (@SQL)	   
		EXEC (@SQL);

		SET @SQL =	N'IF (OBJECT_ID(' + @Quote + @DeleteTriggerName + @Quote + N', ''TR'') IS NOT NULL)' + @NewLine
					+ N'	DROP TRIGGER ' + @DeleteTriggerName;
		--PRINT (@SQL)	   
		EXEC (@SQL);

	------------------------------------------------------
	
	-------Create & Execute triggers----------------------
	
	--let's get the columns off a table that we wish to audit
	DECLARE @tblAuditCols TABLE (AudColID int IDENTITY(1,1) NOT NULL, 
								 ColumnName varchar(128), 
								 ColDesc varchar(128),
								 IsInsertAudit bit,
								 IsUpdateAudit bit,
								 IsDeleteAudit bit)
	INSERT INTO @tblAuditCols
	        (	ColumnName, 
				ColDesc, 
				IsInsertAudit, 
				IsUpdateAudit,
				IsDeleteAudit )
	SELECT	c.ColumnName, 
			c.ColDesc,
			c.IsInsertAudit,
			c.IsUpdateAudit,
			c.IsDeleteAudit
	FROM dbo.vDDColumns c
		JOIN dbo.vDDTables AS t ON t.KeyID = c.DDTablesID
	WHERE t.TableName = @TableName
		AND (c.IsInsertAudit = 1
				OR c.IsDeleteAudit = 1
				OR c.IsUpdateAudit = 1)
	
	-- if we are auditing certain companies, we need to reference that
	IF EXISTS (	SELECT 1 
				FROM dbo.vDDTables AS vdt
					JOIN dbo.vDDAuditTableCompany AS vdatc ON vdt.KeyID = vdatc.DDTableID
				WHERE vdt.TableName = @TableName)
	BEGIN
		-- I'm going to double hit the vDDTables because I only want one row if it exists, the above query might give me more
		SELECT @AuditCompanyString = 'JOIN dbo.vDDAuditTableCompany vdtc ON inserted.' + @CompanyColumn + ' = vdtc.AuditCo ' +
									@NewLine + @TabStops + 'WHERE vdtc.DDTableID = ' + CONVERT(nvarchar(12),vdt.KeyID)
		FROM dbo.vDDTables AS vdt
		WHERE vdt.TableName = @TableName
	END
	ELSE 
	BEGIN
		SET @AuditCompanyString = ''
	END
	
	-- insert trigger 
	SET @SQL = 'CREATE TRIGGER ' + @InsertTriggerName + ' ON ' + @SchemaName + '.' + @TableName + @NewLine
		   + ' AFTER INSERT' + @NewLine + ' NOT FOR REPLICATION AS' + @NewLine
		   + ' SET NOCOUNT ON ' + @NewLine
		   + ' -- generated by vspHQCreateAuditTriggers on ' + CONVERT(VARCHAR(30), GETDATE(), 100) + @NewLine + @NewLine
		   + ' BEGIN TRY ' + @NewLine
		   + @TableVariableStatement + @NewLine
		   ;

		-- create SQL inserts for all the columns we wish to audit
		SELECT	@SQL =	@SQL + '-- log additions to the ' + tac.ColumnName + ' column'	+ @NewLine
							+ @TabStops + 'INSERT dbo.bHQMA (	
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)' + @NewLine
							+ @TabStops +  @OutputClause + @NewLine
							+ @TabStops + 'SELECT '	+  @NewLine
							--table name
							+ @TabStopsP1 + @Quote + @TableName + @Quote + @Seperator	 + @NewLine
							--key string								
							+ @TabStopsP1 + @KeyString + @Seperator + @NewLine
							--company column value, blank if no CO column
							+ @TabStopsP1 + ISNULL('ISNULL(inserted.' + @CompanyColumn + ', '''')', @Quote + @Quote) + @Seperator  + @NewLine
							--Rectype Add/update/delete
							+ @TabStopsP1 + @Quote + 'A' + @Quote + @Seperator  + @NewLine
							--FieldName
							+ @TabStopsP1 + @Quote + ISNULL(tac.ColDesc,tac.ColumnName) + @Quote + @Seperator  + @NewLine
							--OldValue
							+ @TabStopsP1 + 'NULL' + @Seperator  + @NewLine
							--NewValue
							+ @TabStopsP1 + tac.ColumnName + @Seperator  + @NewLine
							--DateTime
							+ @TabStopsP1 + 'GETDATE()' + @Seperator  + @NewLine
							--UserName
							+ @TabStopsP1 + 'SUSER_SNAME()' + @NewLine
							--FKeyID
							+ @TabStops + 'FROM inserted' + @NewLine 
							+ @TabStopsP1 + @AuditCompanyString + @NewLine + @NewLine
			FROM @tblAuditCols AS tac
			WHERE tac.IsInsertAudit = 1
	
	--PRINT (@SQL);
	SET @SQL = @SQL + @HQSAInsertStatement + @NewLine
						+ ' END TRY ' + @NewLine
						+ ' BEGIN CATCH ' + @NewLine
						+ '   DECLARE	@ErrorMessage	NVARCHAR(4000), ' + @NewLine
						+ '				@ErrorSeverity	INT; ' + @NewLine + @NewLine
						+ '   SELECT	@ErrorMessage = ''Error ''+ ISNULL(ERROR_MESSAGE(),'''') +'' in [' +  @SchemaName + '].[' + @InsertTriggerName +'] trigger'', ' + @NewLine
						+ '				@ErrorSeverity = ERROR_SEVERITY(); ' + @NewLine + @NewLine
						+ '   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) ' + @NewLine
						+ ' END CATCH ';
	EXEC (@SQL);

			--------------------------
			-- update trigger 

			SET @SQL = 'CREATE TRIGGER ' + @UpdateTriggerName + ' ON ' + @SchemaName + '.' + @TableName + @NewLine
				   + ' AFTER UPDATE ' + @NewLine + ' NOT FOR REPLICATION AS ' + @NewLine
				   + ' SET NOCOUNT ON ' + @NewLine
				   + ' -- generated by vspHQCreateAuditTriggers on ' + CONVERT(VARCHAR(30), GETDATE(), 100) + @NewLine + @NewLine
				   + ' BEGIN TRY ' + @NewLine
				   + @TableVariableStatement + @NewLine
				   ;
				   
			-- for each column
			SELECT @SQL = @SQL   
								+ @TabStops + 'IF UPDATE([' + c.name + '])' + @NewLine
								+ @TabStops + 'BEGIN'
								+ @TabStops + 'INSERT dbo.bHQMA (	TableName, 
																	KeyString, 
																	Co, 
																	RecType, 
																	FieldName, 
																	OldValue, 
																	NewValue, 
																	DateTime, 
																	UserName)' + @NewLine
								+ @TabStopsP1 +@OutputClause + @NewLine
								+ @TabStops + 'SELECT ' 
								--table name
								+ @TabStops + @Quote + @TableName + @Quote + @Seperator
								--key string
								+ @TabStopsP1 + @KeyString + @Seperator 
								--company column value, blank if no CO column
								+ @TabStopsP1 + ISNULL('inserted.' + @CompanyColumn, @Quote + @Quote) + @Seperator 
								--Rectype Add/update/delete
								+ @TabStopsP1 + @Quote + 'C' + @Quote + @Seperator
								--FieldName
								+ @TabStopsP1 + @Quote + QUOTENAME(c.name) + @Quote + @Seperator 
								--OldValue
								+ @TabStopsP1 + 'CONVERT(VARCHAR(MAX), deleted.[' + c.name + '])' + @Seperator 
								--NewValue
								+ @TabStopsP1 + 'CONVERT(VARCHAR(MAX), inserted.[' + c.name + '])' + @Seperator 
								--DateTime
								+ @TabStopsP1 + 'GETDATE()' + @Seperator 
								--UserName
								+ @TabStopsP1 + 'SUSER_SNAME()' + @NewLine
								--FKeyID
								+ @TabStops + 'FROM inserted' + @NewLine
								+ @TabStopsP1 + 'INNER JOIN deleted' + @NewLine
								+ @TabStopsP1 + '	ON ' + @JoinClause + @NewLine
								+ @TabStopsP1 + '	AND ((inserted.[' + c.name + '] <> deleted.[' + c.name + ']) OR (inserted.[' + c.name + '] IS NULL AND deleted.[' + c.name + '] IS NOT NULL) OR (inserted.[' + c.name + '] IS NOT NULL AND deleted.[' + c.name + '] IS NULL))' + @NewLine
								+ @TabStopsP1 + @AuditCompanyString + @NewLine + @NewLine
								+ @TabStops + 'END ' + @NewLine
								+ @NewLine
				FROM sys.tables AS t
					INNER JOIN sys.columns AS c ON t.[object_id] = c.[object_id]
					INNER JOIN sys.schemas AS s ON s.[schema_id] = t.[schema_id]
					INNER JOIN sys.types AS ty  ON ty.user_type_id = c.user_type_id
					INNER JOIN @tblAuditCols ac ON c.name = ac.ColumnName
				WHERE t.name = @TableName AND s.name = @SchemaName 
					AND c.name NOT IN (@identityColumn)
					AND c.is_computed = 0
					AND ty.name NOT IN ('xml', 'varbinary', 'image', 'text', 'geography', 'bNotes')
					AND ac.IsUpdateAudit = 1
				ORDER BY c.column_id;

				SELECT @SQL = @SQL 
								+ @HQSAInsertStatement + @NewLine
								+ @NewLine
								+ ' END TRY ' + @NewLine
								+ ' BEGIN CATCH ' + @NewLine
								+ '   DECLARE	@ErrorMessage	NVARCHAR(4000), ' + @NewLine
								+ '				@ErrorSeverity	INT; ' + @NewLine + @NewLine
								+ '   SELECT	@ErrorMessage = ''Error ''+ ISNULL(ERROR_MESSAGE(),'''') +'' in [' +  @SchemaName + '].[' + @UpdateTriggerName +'] trigger'', ' + @NewLine
								+ '				@ErrorSeverity = ERROR_SEVERITY(); ' + @NewLine + @NewLine
								+ '   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) ' + @NewLine
								+ ' END CATCH ';
				
			--PRINT (@SQL);
			--PRINT (LEN(@SQL));	   
			EXEC (@SQL);

		--------------------------
		-- delete trigger 
		
		SET @SQL = 'CREATE TRIGGER ' + @DeleteTriggerName + ' ON ' + @SchemaName + '.' + @TableName + @NewLine
			   + ' AFTER DELETE' + @NewLine + ' NOT FOR REPLICATION AS' + @NewLine
			   + ' SET NOCOUNT ON ' + @NewLine
			   + ' -- generated by vspHQCreateAuditTriggers on ' + CONVERT(VARCHAR(30), GETDATE(), 100) + @NewLine + @NewLine
			   + ' BEGIN TRY ' + @NewLine
			   + @TableVariableStatement + @NewLine
			   ;
			
		SELECT	@SQL =	@SQL
					+ @TabStops + 'INSERT dbo.HQMA (
													TableName, 
													KeyString, 
													Co, 
													RecType, 
													FieldName, 
													OldValue, 
													NewValue, 
													DateTime, 
													UserName)' + @NewLine
					+ @TabStopsP1 + @OutputClause + @NewLine
					+ @TabStops + 'SELECT' + @NewLine
					--table name
					+ @TabStopsP1 + @Quote + @TableName + @Quote + @Seperator
					--key string
					+ @TabStopsP1 + REPLACE(@KeyString, 'inserted.', 'deleted.') + @Seperator 
					--company column value, blank if no CO column
					+ @TabStopsP1 + ISNULL('deleted.' + @CompanyColumn, @Quote + @Quote) + @Seperator 
					--Rectype Add/update/delete
					+ @TabStopsP1 + @Quote + 'D' + @Quote + @Seperator
					--FieldName
					+ @TabStopsP1 + 'NULL' + @Seperator 
					--OldValue
					+ @TabStopsP1 + 'NULL' + @Seperator 
					--NewValue
					+ @TabStopsP1 + 'NULL' + @Seperator 
					--DateTime
					+ @TabStopsP1 + 'GETDATE()' + @Seperator 
					--UserName
					+ @TabStopsP1 + 'SUSER_SNAME()' + @NewLine 
					--FKeyID
					--+ 'deleted.KeyID' + @NewLine
					+ @TabStops + 'FROM deleted' + @NewLine
				FROM @tblAuditCols		
				WHERE IsDeleteAudit = 1
					
					
				SET @SQL = @SQL + @NewLine +
					+ @TabStops + @HQSAInsertForDeleteStatement + @NewLine
					+ ' END TRY ' + @NewLine
					+ ' BEGIN CATCH ' + @NewLine
					+ '   DECLARE	@ErrorMessage	NVARCHAR(4000), ' + @NewLine
					+ '				@ErrorSeverity	INT; ' + @NewLine + @NewLine
					+ '   SELECT	@ErrorMessage = ''Error ''+ ISNULL(ERROR_MESSAGE(),'''') +'' in [' +  @SchemaName + '].[' + @DeleteTriggerName +'] trigger'', ' + @NewLine
					+ '				@ErrorSeverity = ERROR_SEVERITY(); ' + @NewLine + @NewLine
					+ '   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) ' + @NewLine
					+ ' END CATCH '; 
		--PRINT (@SQL)	   
		EXEC (@SQL);
	
	------------------------------------------------------	
	
	--Set audit triggers to be last in the firing sequence	
	SET @SQL = 'sp_settriggerorder @triggername= ' + @Quote + @InsertTriggerName + @Quote + ', @order=''Last'', @stmttype = ''INSERT''; ';
	--PRINT (@SQL)	   
	EXEC (@SQL);
	
	SET @SQL = 'sp_settriggerorder @triggername= ' + @Quote + @UpdateTriggerName + @Quote + ', @order=''Last'', @stmttype = ''UPDATE''; ';
	--PRINT (@SQL) 
	EXEC (@SQL);

	SET @SQL = 'sp_settriggerorder @triggername= ' + @Quote + @DeleteTriggerName + @Quote + ', @order=''Last'', @stmttype = ''DELETE''; ';
	--PRINT (@SQL)
	EXEC (@SQL);

END





/****** Object:  StoredProcedure [dbo].[vspDMGetIndexColumnsForDDFHBatchPostingTable]    Script Date: 12/09/2010 09:27:16 ******/
SET ANSI_NULLS ON

GO
GRANT EXECUTE ON  [dbo].[vspDDCreateAuditTriggers] TO [public]
GO
