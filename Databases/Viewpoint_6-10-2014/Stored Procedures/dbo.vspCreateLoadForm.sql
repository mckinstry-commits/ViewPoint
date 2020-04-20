SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Created by: JayR  2013-06-10 TFS-41459 Stored procedure for the extraction of form data.  
--  Modified:  JayR  2013-06-11 TFS-41459 Removed dead code.  
--
-- select * from vDDFH  
-- exec vspCreateLoadForm 'AP1099Download', 'This is a comment'
-- select * from DDTables
-- select * FROM vDDFI WHere Form = 'AP1099Download' order by Form, Seq 

CREATE PROCEDURE [dbo].[vspCreateLoadForm] (@Form AS VARCHAR(30))
AS
  DECLARE @LineTerm VARCHAR(10);
  DECLARE @tableName VARCHAR(128);
  DECLARE @extractOrder VARCHAR(255);
  DECLARE @whereClause VARCHAR(2000);
  DECLARE @quoteForm VARCHAR(32);  --Add single tics to name
  DECLARE @tmpOutputScript VARCHAR(MAX);
  DECLARE @OutputScript VARCHAR(MAX);
  DECLARE @hasIdentityCol AS BIT;
  DECLARE @TurnOffIdentity AS VARCHAR(MAX);
  DECLARE @OmitIdentity AS BIT;
  DECLARE @NumRows INT;
  DECLARE @quote char(1);
  
  SET @quote = char(39);
  
  SET @OutputScript = '';
  SET @tmpOutputScript = '';
  
  DECLARE vcTable CURSOR FAST_FORWARD FOR
	SELECT TableName,ExtractOrder, WhereClause, OmitIdentity
    FROM vDDFormExport t
    ORDER BY ExtractStep
    
  SET @LineTerm = CHAR(13) + CHAR(10);

  SET @OutputScript = @OutputScript + 
  ' BEGIN TRANSACTION 
    BEGIN TRY
    DECLARE @errMsg VARCHAR(2000);
    SET @errMsg = ''''; 
  ' + @LineTerm ;

  --Disable FKs
  SET @OutputScript = @OutputScript + ' -- Disable Forgein Keys on table ' + @LineTerm;
  OPEN vcTable;
  FETCH NEXT FROM vcTable INTO @tableName, @extractOrder, @whereClause, @OmitIdentity
  WHILE @@FETCH_STATUS = 0
  BEGIN
    SET @OutputScript = @OutputScript + 'ALTER TABLE [' + @tableName + '] NOCHECK CONSTRAINT ALL;' + @LineTerm;
	FETCH NEXT FROM vcTable INTO @tableName, @extractOrder, @whereClause, @OmitIdentity
  END
  CLOSE vcTable;

  OPEN vcTable;
  FETCH NEXT FROM vcTable INTO @tableName, @extractOrder, @whereClause, @OmitIdentity
  WHILE @@FETCH_STATUS = 0
	  BEGIN
			SET @quoteForm = '''' + @Form + '''';
			IF ISNULL(@whereClause,'') = '' 
			BEGIN
				--This is the default Where clause
				SET @whereClause = 'WHERE [Form] = <<FORM>> ';
			END
			SET @whereClause = REPLACE(@whereClause,'<<FORM>>', @quoteForm);
			
			EXEC dbo.vspGenerateInserts @table_name = @tableName, @where=@whereClause, @disable_triggers=1, @delete_target=1, @ommit_identity=@OmitIdentity, @OutputScript=@tmpOutputScript OUTPUT, @NumRows = @NumRows OUTPUT;
				
			SET @OutputScript = @OutputScript + @tmpOutputScript;

			FETCH NEXT FROM vcTable INTO @tableName, @extractOrder, @whereClause, @OmitIdentity;
	  END;
	  CLOSE vcTable;
  
  --Enable FKs
  SET @OutputScript = @OutputScript + ' -- Enable Forgein Keys on table ' + @LineTerm;
  OPEN vcTable;
  FETCH NEXT FROM vcTable INTO @tableName, @extractOrder, @whereClause, @OmitIdentity
  WHILE @@FETCH_STATUS = 0
  BEGIN
    SET @OutputScript = @OutputScript + 'ALTER TABLE [' + @tableName + '] CHECK CONSTRAINT ALL;' + @LineTerm;
	FETCH NEXT FROM vcTable INTO @tableName, @extractOrder, @whereClause, @OmitIdentity
  END
  CLOSE vcTable;
  
  DECLARE vcTableIdentity CURSOR FAST_FORWARD FOR
	SELECT t.TableName
    FROM vDDFormExport t
      JOIN sysobjects obj
        ON t.TableName = obj.name
      JOIN syscolumns col
        ON obj.id = col.id 
      WHERE obj.xtype = 'U' --Table
      AND col.[status]  & 128 = 128 --Identity Column
    ORDER BY ExtractStep
  
  SET @TurnOffIdentity = '';
  OPEN vcTableIdentity;
  FETCH NEXT FROM vcTableIdentity INTO @tableName;
  WHILE @@FETCH_STATUS = 0
  BEGIN
    SET @TurnOffIdentity = @TurnOffIdentity + '			SET IDENTITY_INSERT [' + @tableName + '] OFF;' + @LineTerm;
	FETCH NEXT FROM vcTableIdentity INTO @tableName;
  END
  CLOSE vcTableIdentity;
  
  DEALLOCATE vcTable;
  DEALLOCATE vcTableIdentity;
  
  SET @OutputScript = @OutputScript 
		+ ' 
		    COMMIT TRANSACTION;
		END TRY 
		BEGIN CATCH
			SET @errMsg = ''ERROR: Form:' + @Form + ''' + CAST(ERROR_NUMBER() as varchar(10)) + '' '' + ERROR_MESSAGE();
			ROLLBACK;
			' + @TurnOffIdentity + '
			RAISERROR(@errMsg, 11, -1);
		END CATCH '  + @LineTerm ;
  
  SELECT @OutputScript AS FormInsert, @NumRows AS NumRows;
   

GO
GRANT EXECUTE ON  [dbo].[vspCreateLoadForm] TO [public]
GO
