SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspfix2012RaiseError] 
(
  @preview varchar(1)
)
AS 
BEGIN
	/*
	Author:		JayR
	Create date: 5/11/2012
	Description:  See below.
    Note:  We assume someone isn't evil enought to spread the raiserror over multiple lines.
	
	The purposed of this script is too solve a incompatibility with SQL Serve 2012 and some raiserror syntax.
	  This is accomplished by.
	  1. Finding all bad calls to raiserror
	  2. Constructing a replacement
	  3. Applying the replacment to the database. 
	  
	Testing:
	-- This runs in in preview mode
	-- EXEC vspfix2012RaiseError 'Y'
	-- 
	-- This runs it in update mode:
	-- EXEC vspfix2012RaiseError 'N'
	*/

	DECLARE @type AS VARCHAR(10)
	DECLARE @objName AS NVARCHAR(2000)
	DECLARE @objSchema AS NVARCHAR(2000)
	DECLARE @before_def AS NVARCHAR(MAX)
	DECLARE @after_def AS NVARCHAR(MAX)
	DECLARE @drop_sql NVARCHAR(2000)
	DECLARE @maxLoop AS INT   --Prevent this from running too long it something goes wrong
	DECLARE @numProcessed AS INT 
	DECLARE @numErrored AS INT 
	DECLARE @errList AS NVARCHAR(max)
	DECLARE @nameErrored AS VARCHAR(512) 
	DECLARE @maxErrored AS INT 
	DECLARE @lastProgressCount AS INT
	
	SET @maxLoop = 5000  --Prevent this from running too long it something goes wrong
	SET @numProcessed = 0
	SET @numErrored  = 0
	SET @nameErrored  = '  '
	SET @maxErrored  = 50
	SET @lastProgressCount  = 0
	SET @errList = ''
	
	IF(ISNULL(@preview,'Y') <> 'N')
		SET @preview = 'Y'
	
	CREATE TABLE #tmpBeforeAfter(
		--checksum_id integer
		obj_name NVARCHAR(255)
		, [before_def] NVARCHAR(MAX)
		, [after_def] NVARCHAR(MAX)
		)
		
	CREATE INDEX idx_tmpBeforeAfter ON #tmpBeforeAfter(obj_name)
	
	--Cursor to find all the placing an invalid call to raiserror is used	
    DECLARE curBadRaise CURSOR
    FOR
	SELECT TOP (@maxLoop) 
	obj.type
	, mods.[definition]
	, QUOTENAME(obj.name) AS obj_name  
	, QUOTENAME(sch.name) AS [schema_name]  --We are restricting this to schema dbo
	FROM sys.sql_modules mods
	JOIN sys.objects obj
	  ON mods.object_id = obj.object_id
	JOIN sys.schemas sch
	  ON obj.schema_id = sch.schema_id
	WHERE (
		-- A regular expression would be very very nice here.  I want \w
		LOWER(definition) LIKE '%raiserror [0-9]%'
		OR LOWER(definition) LIKE '%raiserror  [0-9]%'
		OR LOWER(definition) LIKE '%raiserror   [0-9]%'
		OR LOWER(definition) LIKE '%raiserror' + CHAR(9) + '[0-9]%'
		OR LOWER(definition) LIKE '%raiserror' + CHAR(9) + ' [0-9]%'
		OR LOWER(definition) LIKE '%raiserror ' + CHAR(9) + '[0-9]%'
	)
	AND obj.[type] IN ('TR','P')
	AND sch.name = 'dbo'
	AND obj.name NOT LIKE 'vspfix2012RaiseError%'
	--AND ABS(CHECKSUM(obj.name)) % 7 = 0  --Do a sample of the code
	
	BEGIN TRY
		OPEN curBadRaise
		
		FETCH NEXT FROM curBadRaise INTO @type, @before_def, @objName, @objSchema
		WHILE (@@FETCH_STATUS <>  -1)
		BEGIN
			SET @maxLoop = @maxLoop - 1
			IF(@maxLoop < 0)
				RAISERROR('Max loop exceeded. We are looping forever or code base is larger than expected',11,-1)
			   
			IF(@type = 'TR') 
			BEGIN
				SET @drop_sql = 'DROP TRIGGER ' + @objSchema + '.' + @objName
			END
			ELSE IF(@type = 'P')
			BEGIN
				SET @drop_sql = 'DROP PROCEDURE ' + @objSchema + '.' + @objName
			END
			ELSE 
			BEGIN
				RAISERROR('This code is not designed to handle only triggers and stored procedures',11,-1)
			END
			
			IF(@preview = 'N')
				BEGIN
					BEGIN TRY
						BEGIN TRANSACTION
						
						EXEC vspfix2012RaiseErrorText @before_def, @after_def OUT
						
						IF(@after_def IS NULL OR LEN(@after_def) < 10)
							RAISERROR('The @after_def is crazy',11,-1)
					
						EXECUTE sp_executesql @drop_sql

						EXECUTE sp_executesql @after_def
					
						COMMIT TRANSACTION
						
						SET @numProcessed = @numProcessed + 1
					END TRY
					BEGIN CATCH
						ROLLBACK TRANSACTION
						-- The left and right bracket are wildcards with the LIKE operator somewhat like %
						IF REPLACE(REPLACE(@nameErrored,'[','<'),']','>') NOT LIKE '%' + REPLACE(REPLACE(@objName,'[','<'),']','>') + '%'
						BEGIN
							SET @numErrored = @numErrored + 1
							SET @nameErrored = 	@nameErrored + ' ' + @objName
							SET @errList = @errList + '  ' + ERROR_MESSAGE()
							IF LEN(@errList) > 153
							BEGIN
								SET @errList = LEFT(@errList,150) + '...'	
							END
						END
					END CATCH
					IF(@numErrored >= @maxErrored)
						RAISERROR('Too Many recompiles failed:',11,-1)
				END
			ELSE
				BEGIN
					EXEC vspfix2012RaiseErrorText @before_def, @after_def OUT
				
					INSERT INTO #tmpBeforeAfter (obj_name, [before_def],[after_def]) 
					SELECT @objName, @before_def, @after_def
					WHERE NOT EXISTS 
					   (
					   SELECT 1 
					   FROM #tmpBeforeAfter 
					   WHERE [obj_name] = @objName
					   AND [before_def] = @before_def
					   AND [after_def] = @after_def
					   )
				END
			   
			FETCH NEXT FROM curBadRaise INTO @type, @before_def, @objName, @objSchema
			
			-- You can have multiple raiserrors in a trigger/procedure and such so we may restart the loop.
			IF(@@FETCH_STATUS = -1
			AND @lastProgressCount <> @numProcessed
			AND @maxLoop > 0)
				BEGIN
					SET @lastProgressCount = @numProcessed
					CLOSE curBadRaise
					OPEN curBadRaise
					FETCH NEXT FROM curBadRaise INTO @type, @before_def, @objName, @objSchema
				END
		END
		
		IF(@preview = 'Y')
			SELECT * FROM #tmpBeforeAfter
			ORDER BY [obj_name]
		
		PRINT 'Number Processed:' + CAST(@numProcessed AS VARCHAR(10))
		PRINT 'Failed recompiles:' + @nameErrored
	END TRY
	
	
	BEGIN CATCH
		PRINT 'ERROR Encountered in fixing SQL Server 2012 Raiserror Issue ' + ERROR_MESSAGE()
		PRINT 'Object we may be dealing with at the time of the error:' + @objName
		PRINT 'Number Processed before error:' + CAST(@numProcessed AS VARCHAR(10))
		PRINT 'Failed recompiles:' + @nameErrored
		PRINT 'Error List:' + @errList
		PRINT 'Before image may be:' + @before_def
		ROLLBACK TRANSACTION
	END CATCH;
	
	CLOSE curBadRaise
	DEALLOCATE curBadRaise
	
END
GO
GRANT EXECUTE ON  [dbo].[vspfix2012RaiseError] TO [public]
GO
