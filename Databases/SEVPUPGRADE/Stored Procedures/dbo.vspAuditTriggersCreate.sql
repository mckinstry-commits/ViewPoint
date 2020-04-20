SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[vspAuditTriggersCreate]
/***********************************************************************
*	Created by: 	AR  
*	Created Date:	3/8/2011
*	Purpose:	Stored procedure to automatically generate audit triggers.  I stole this code from
				vspHQCreateAuditTriggers written by Charles C.  I'm changing it to use DD Audit tables 
				to drive
				
 
*	Altered by:		AR 
*	Modified:		AR 4/1/2011 - changing vDDTables to vAuditTables
*                   JayR 7/23/2012 - Add better error handling.
*							
*	Usage:			TableName is the name of the table to create the triggers on,
* 					KeyColumnList is a comma delimited list of columns that reflect the form key value
*					
* 
***********************************************************************/
	  @TableName NVARCHAR(128) = NULL
	WITH EXECUTE AS 'viewpointcs'

AS  
BEGIN
	SET NOCOUNT ON;

	-----Initial Validation----
	IF @TableName IS NULL
		RAISERROR(N'@TableName parameter cannot be null.', 16, 1);

-----Setup----------------

	DECLARE 
		  @SQL								NVARCHAR(MAX)
		, @errMsg							NVARCHAR(4000)
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
		, @TabStops							NVARCHAR(256)
		, @TabStopsP1						NVARCHAR(256)
		, @AuditCompanyString				NVARCHAR(MAX)
		, @CompanyColumn					NVARCHAR(128)
		, @GroupColumn						NVARCHAR(128)
		, @AuditByCo						CHAR(1)
		, @AuditByGroup						CHAR(1)
		, @AuditFlagID						SMALLINT
		;
		
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
	
	-- do we audit by company, group or neither
	SELECT	@AuditByCo = vaf.AuditByCompany,
			@AuditByGroup = vaf.AuditByGroup,
			@AuditFlagID = vaf.KeyID
	FROM	dbo.vAuditTables AS vdt
			JOIN dbo.vAuditFlagTables ft ON vdt.KeyID = ft.AuditTableID
			JOIN dbo.vAuditFlags AS vaf ON vaf.KeyID = ft.AuditFlagID
		--Don't use DDFI because type 3 is not accurate all the time
	WHERE
		vdt.TableName = @TableName

	IF @AuditByGroup = 'Y'  -- audit by group get the group columns
	BEGIN 
		SELECT @GroupColumn = vc.ColumnName
		FROM	dbo.vAuditTables AS vdt
			JOIN dbo.vAuditColumns AS vc ON vdt.KeyID = vc.AuditTablesID 
			--Don't use DDFI because type 3 is not accurate all the time
		WHERE
			vdt.TableName = @TableName
			AND vc.IsGroup = 'Y'
	END 
	ELSE 
	BEGIN
		-- company is needed for co column in HQMA, we still need to get it 
		SELECT @CompanyColumn = vc.ColumnName
		FROM	dbo.vAuditTables AS vdt
			JOIN dbo.vAuditColumns AS vc ON vdt.KeyID = vc.AuditTablesID 
			--Don't use DDFI because type 3 is not accurate all the time
		WHERE
			vdt.TableName = @TableName
			AND vc.IsCo = 'Y'
	END

	-- using DDFI via Charles C suggestion (doesn't work because DDFI isn't guarenteed to be correct)
	--SELECT @KeyString = @KeyString + COALESCE(vc.ColumnDesc,vc.ColumnName) + N' = "' + @Quote 
	--					+ N' + REPLACE(CAST(inserted.' + QUOTENAME(COALESCE(vc.ColumnDesc,vc.ColumnName))
	--					+ N' AS VARCHAR(MAX)),''"'', ''&quot;'') + ' + @Quote + N'" '
	--FROM	dbo.vAuditTables AS vdt
	--	JOIN dbo.vAuditColumns AS vc ON vdt.KeyID = vc.AuditTablesID 
	--	--Don't use DDFI because type 3 is not accurate all the time
	--WHERE
	--	vdt.TableName = @TableName
	--	AND vc.IsKey = 'Y'
	--ORDER BY vc.ColumnName
	SELECT @KeyString = @KeyString + COALESCE(vc.ColumnDesc,vc.ColumnName) + N' = "' + @Quote 
						+ N' + REPLACE(CAST(ISNULL(inserted.' + QUOTENAME(COALESCE(vc.ColumnDesc,vc.ColumnName))
						+ N','''') AS VARCHAR(MAX)),''"'', ''&quot;'') + ' + @Quote + N'" '
	FROM	dbo.vAuditTables AS vdt
		JOIN dbo.vAuditColumns AS vc ON vdt.KeyID = vc.AuditTablesID 
		--Don't use DDFI because type 3 is not accurate all the time
	WHERE
		vdt.TableName = @TableName
		AND vc.IsKey = 'Y'
	ORDER BY vc.ColumnName

	SELECT @KeyString = @KeyString + @KeyStringTerminator;

	-- if we have an identity use it				
	IF @identityColumn IS NOT NULL
	BEGIN
		SET @JoinClause = N' inserted.[' + @identityColumn + '] = deleted.[' + @identityColumn + '] ';
	END
	ELSE
	BEGIN
		SET @JoinClause = N'';			
		
		SELECT @JoinClause = @JoinClause + ' inserted.' + QUOTENAME(vdc.ColumnName) + ' = deleted.' + QUOTENAME(vdc.ColumnName) + ' ' + @JoinConcatination
		FROM dbo.vAuditColumns AS vdc
			JOIN dbo.vAuditTables AS vdt ON vdt.KeyID = vdc.AuditTablesID
			-- these joins ensure the columns really exist, to eliminate errors
			JOIN sys.tables st ON st.name = vdt.TableName
			JOIN sys.columns AS sc ON sc.[object_id] = st.[object_id] AND sc.[name] = vdc.ColumnName
		WHERE vdc.IsKey = 'Y'
			AND vdt.TableName = @TableName
				
		SELECT @JoinClause = LEFT(@JoinClause, LEN(@JoinClause) - LEN(@JoinConcatination));
	END	
	
	---------Build Output Clauses & HQSA Insert------------
	--Only required if there are securable datatypes on the table
	IF EXISTS(	SELECT 1 
				FROM dbo.DDSLShared
				WHERE TableName = @TableName
			 )
	BEGIN
	-- Use this commented section when adding FKeyID back to HQMA
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
				FROM dbo.DDSLShared
					INNER JOIN dbo.DDDTShared ON DDSLShared.Datatype = DDDTShared.Datatype
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
								 IsInsertAudit CHAR(1),
								 IsUpdateAudit CHAR(1),
								 IsDeleteAudit CHAR(1)
								 )
	INSERT INTO @tblAuditCols
	        (	ColumnName, 
				ColDesc, 
				IsInsertAudit, 
				IsUpdateAudit,
				IsDeleteAudit )
	SELECT	c.ColumnName, 
			c.ColumnDesc,
			c.IsInsertAudit,
			c.IsUpdateAudit,
			c.IsDeleteAudit
	FROM dbo.vAuditColumns c
		JOIN dbo.vAuditTables AS t ON t.KeyID = c.AuditTablesID
		-- these joins ensure the columns really exist, to eliminate errors
		JOIN sys.tables st ON st.name = t.TableName
		JOIN sys.columns AS sc ON sc.[object_id] = st.[object_id] AND sc.[name] = c.ColumnName
		JOIN sys.types AS sty ON sty.user_type_id = sc.user_type_id
	WHERE t.TableName = @TableName
		-- remove LOB fields
	    AND sty.[name] NOT IN ('xml', 'varbinary', 'image', 'text', 'geography', 'bNotes')
		AND sc.max_length <> -1				
		AND (c.IsInsertAudit = 'Y'
				OR c.IsDeleteAudit = 'Y'
				OR c.IsUpdateAudit = 'Y')
		AND sc.is_computed = 0
	ORDER BY sc.name
	
	IF EXISTS (SELECT COUNT(*) FROM @tblAuditCols HAVING COUNT(*) = 0) 
	BEGIN
		SET @errMsg = 'Select pulled no data. Possible reasons:  No columns, columns there are invalid type, typo in audit table setup... Table:' + @TableName;
		RAISERROR(@errMsg, 11, -1)
		RETURN
	END
	
	-- audit group first
	IF @AuditByGroup = 'Y'
	BEGIN
		-- I'm going to double hit the vAuditTables because I only want one row if it exists, the above query might give me more
		SELECT @AuditCompanyString = 'JOIN dbo.vAuditFlagGroup afg ON inserted.' + @GroupColumn + ' = afg.AuditGroup' + 
									@NewLine + @TabStops + 'WHERE afg.AuditFlagID = ' + CONVERT(nvarchar(12),@AuditFlagID)
	END
	-- if we are auditing certain companies, we need to reference that
	ELSE IF @AuditByCo = 'Y'
	BEGIN
		-- I'm going to double hit the vAuditTables because I only want one row if it exists, the above query might give me more
		SELECT @AuditCompanyString = 'JOIN dbo.vAuditFlagCompany AS afc ON inserted.' + @CompanyColumn + ' = afc.AuditCo ' +
									@NewLine + @TabStops + 'WHERE afc.AuditFlagID = ' + CONVERT(nvarchar(12),@AuditFlagID)
	END
	ELSE 
	BEGIN
		SELECT @AuditCompanyString = ''
	END

	-- insert trigger 
	SET @SQL = 'CREATE TRIGGER ' + @InsertTriggerName + ' ON ' + @SchemaName + '.' + @TableName + @NewLine
		   + ' AFTER INSERT' + @NewLine + ' NOT FOR REPLICATION AS' + @NewLine
		   + ' SET NOCOUNT ON ' + @NewLine
		   + ' -- generated by vspAuditTriggersCreate' + @NewLine + @NewLine
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
							+ @TabStopsP1 + ISNULL('ISNULL(inserted.' + ISNULL(@GroupColumn,@CompanyColumn) + ', '''')', @Quote + @Quote) + @Seperator  + @NewLine
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
			WHERE tac.IsInsertAudit = 'Y'
	
	
	SET @SQL = @SQL + @HQSAInsertStatement + @NewLine
						+ ' END TRY ' + @NewLine
						+ ' BEGIN CATCH ' + @NewLine
						+ '   DECLARE	@ErrorMessage	NVARCHAR(4000), ' + @NewLine
						+ '				@ErrorSeverity	INT; ' + @NewLine + @NewLine
						+ '   SELECT	@ErrorMessage = ''Error ''+ ISNULL(ERROR_MESSAGE(),'''') +'' in [' +  @SchemaName + '].[' + @InsertTriggerName +'] trigger'', ' + @NewLine
						+ '				@ErrorSeverity = ERROR_SEVERITY(); ' + @NewLine + @NewLine
						+ '   RAISERROR(@ErrorMessage, @ErrorSeverity, 1 ) ' + @NewLine
						+ ' END CATCH ';
	--PRINT (@SQL);
	EXEC (@SQL);

			--------------------------
			-- update trigger 

			SET @SQL = 'CREATE TRIGGER ' + @UpdateTriggerName + ' ON ' + @SchemaName + '.' + @TableName + @NewLine
				   + ' AFTER UPDATE ' + @NewLine + ' NOT FOR REPLICATION AS ' + @NewLine
				   + ' SET NOCOUNT ON ' + @NewLine
				   + ' -- generated by vspAuditTriggersCreate' + @NewLine + @NewLine
				   + ' BEGIN TRY ' + @NewLine
				   + @TableVariableStatement + @NewLine
				   ;
				   
			-- for each column
			SELECT @SQL = @SQL   
								+ @TabStops + 'IF UPDATE([' + ac.ColumnName + '])' + @NewLine
								+ @TabStops + 'BEGIN'  + @NewLine
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
								+ @TabStopsP1 + 'SELECT ' 
								--table name
								+ @TabStops + @Quote + @TableName + @Quote + @Seperator
								--key string
								+ @TabStopsP1 + @KeyString + @Seperator 
								--company column value, blank if no CO column
								+ @TabStopsP1 + ISNULL('inserted.' + ISNULL(@GroupColumn,@CompanyColumn), @Quote + @Quote) + @Seperator 
								--Rectype Add/update/delete
								+ @TabStopsP1 + @Quote + 'C' + @Quote + @Seperator
								--FieldName
								+ @TabStopsP1 + @Quote + ISNULL(ColDesc,ColumnName) + @Quote + @Seperator 
								--OldValue
								+ @TabStopsP1 + 'CONVERT(VARCHAR(MAX), deleted.[' + ac.ColumnName + '])' + @Seperator 
								--NewValue
								+ @TabStopsP1 + 'CONVERT(VARCHAR(MAX), inserted.[' + ac.ColumnName+ '])' + @Seperator 
								--DateTime
								+ @TabStopsP1 + 'GETDATE()' + @Seperator 
								--UserName
								+ @TabStopsP1 + 'SUSER_SNAME()' + @NewLine
								--FKeyID
								+ @TabStops + 'FROM inserted' + @NewLine
								+ @TabStopsP1 + 'INNER JOIN deleted' + @NewLine
								+ @TabStopsP1 + '	ON ' + @JoinClause + @NewLine
								+ @TabStopsP1 + '	AND ((inserted.[' + ac.ColumnName + '] <> deleted.[' + ac.ColumnName + ']) OR (inserted.[' + ac.ColumnName + '] IS NULL AND deleted.[' + ac.ColumnName + '] IS NOT NULL) OR (inserted.[' + ac.ColumnName + '] IS NOT NULL AND deleted.[' + ac.ColumnName + '] IS NULL))' + @NewLine
								+ @TabStopsP1 + @AuditCompanyString + @NewLine + @NewLine
								+ @TabStops + 'END ' + @NewLine
								+ @NewLine
				FROM  @tblAuditCols ac
				WHERE ac.IsUpdateAudit = 'Y'

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
			   + ' -- generated by vspAuditCreateAuditTriggers' + @NewLine + @NewLine
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
					+ @TabStopsP1 + @Quote + @TableName + @Quote + @Seperator  + @NewLine
					--key string
					+ @TabStopsP1 + REPLACE(@KeyString, 'inserted.', 'deleted.') + @Seperator  + @NewLine
					--company column value, blank if no CO column
					+ @TabStopsP1 + ISNULL('deleted.' + ISNULL(@GroupColumn,@CompanyColumn), @Quote + @Quote) + @Seperator  + @NewLine
					--Rectype Add/update/delete
					+ @TabStopsP1 + @Quote + 'D' + @Quote + @Seperator	    + @NewLine
					--FieldName
					+ @TabStopsP1 + @Quote +ISNULL(ColDesc,ColumnName) + @Quote + @Seperator	  + @NewLine
					--OldValue
					+ @TabStopsP1 + 'CONVERT(VARCHAR(MAX), deleted.[' + ColumnName + '])' + @Seperator 
					--NewValue
					+ @TabStopsP1 + 'NULL' + @Seperator + @NewLine 
					--DateTime
					+ @TabStopsP1 + 'GETDATE()' + @Seperator   + @NewLine
					--UserName
					+ @TabStopsP1 + 'SUSER_SNAME()' + @NewLine 
					--FKeyID
					--+ 'deleted.KeyID' + @NewLine
					+ @TabStops + 'FROM deleted' + @NewLine
					+ @TabStopsP1 + REPLACE(@AuditCompanyString, 'inserted.', 'deleted.') + @NewLine
				FROM @tblAuditCols		
				WHERE IsDeleteAudit = 'Y'
					
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
	SET @SQL = N'IF (OBJECT_ID(' + @Quote + @InsertTriggerName + @Quote + N', ''TR'') IS NOT NULL)' + @NewLine
				+ 'EXEC sp_settriggerorder @triggername= ' + @Quote + @InsertTriggerName + @Quote + ', @order=''Last'', @stmttype = ''INSERT''; ';
	--PRINT (@SQL)	   
	EXEC (@SQL);
	
	SET @SQL = N'IF (OBJECT_ID(' + @Quote + @UpdateTriggerName + @Quote + N', ''TR'') IS NOT NULL)' + @NewLine
				+ 'EXEC sp_settriggerorder @triggername= ' + @Quote + @UpdateTriggerName + @Quote + ', @order=''Last'', @stmttype = ''UPDATE''; ';
	--PRINT (@SQL) 
	EXEC (@SQL);

	SET @SQL = N'IF (OBJECT_ID(' + @Quote + @DeleteTriggerName + @Quote + N', ''TR'') IS NOT NULL)' + @NewLine
				+ 'EXEC sp_settriggerorder @triggername= ' + @Quote + @DeleteTriggerName + @Quote + ', @order=''Last'', @stmttype = ''DELETE''; ';
	--PRINT (@SQL)
	EXEC (@SQL);

END



GO
GRANT EXECUTE ON  [dbo].[vspAuditTriggersCreate] TO [public]
GO
