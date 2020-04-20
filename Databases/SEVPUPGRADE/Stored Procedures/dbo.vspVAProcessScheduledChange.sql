SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jonathan Paullin
-- Create date: 12/01/2009
-- MODIFIED By :	CG 12/03/2010 Issue #140507 - Changed to no longer require column named "KeyID" to indicate identity column
-- Description:	This procedure will process a single scheduled change.
-- =============================================

CREATE PROCEDURE [dbo].[vspVAProcessScheduledChange]
	(@table nvarchar(128), @column nvarchar(128), @keyIDToUpdate bigint, 
	 @newValue nvarchar(max), @scheduledChangeKeyID int, @errorMessage nvarchar(512) output)
	
AS
BEGIN	
	SET NOCOUNT ON;   
	
	DECLARE @returnCode INT;
	SELECT @returnCode = 0;				
	
	DECLARE @updateStatus varchar(30), @updateMessage varchar(max);
		
	-- Make sure table exists
	IF object_id(@table) is null
	BEGIN
		SELECT @errorMessage = 'Table ' + @table + ' does not exist.', @returnCode = 1;
		GOTO vspExit;
	END
		
	-- Make sure the column to update exists
	IF NOT EXISTS (SELECT * FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = @table AND COLUMN_NAME = @column)
	BEGIN
		SELECT @errorMessage = 'Column ' + @column + ' does not exist for table ' + @table + '.', @returnCode = 1;
		GOTO vspExit;
	END	
		
	-- Get the identity column of the table
	declare @identityColumn varchar(128)
	exec vspDDGetIdentityColumn @table, @identityColumn output			
		
	BEGIN TRY								
		-- Build the update statement.		
		DECLARE @updateStatement nvarchar(max);
		SET @updateStatement = N'UPDATE ' + QUOTENAME(@table) +  N' SET ' + QUOTENAME(@column) + 
							   N' = @NewValue WHERE ' + @identityColumn + ' = @KeyIDToUpdate';
							   
		-- Build the parameter definition.					   
		DECLARE @parameterDefinition nvarchar(max);						
		SET @parameterDefinition = N'@Table varchar(128), @Column varchar(128), @NewValue varchar(max), @KeyIDToUpdate bigint';
						   										   								   			
		-- Update the record.
		EXEC sp_executesql @updateStatement, @parameterDefinition, @Table = @table, @Column = @column, 
						   @NewValue = @newValue, @KeyIDToUpdate = @keyIDToUpdate;
								
		IF @@ROWCOUNT = 0
		BEGIN
			SELECT @errorMessage = 'The record to update does not exist.', @returnCode = 1;
			GOTO vspExit;
		END				
		
	END TRY
	BEGIN CATCH
		SELECT @errorMessage = 'Error: ' + error_message(), @returnCode = 1;		
	END CATCH	
	
vspExit:	

	-- Update the status and message.
	IF @returnCode = 1	
		SELECT @updateMessage = @errorMessage, @updateStatus = 'Error';	
	ELSE	
		SELECT @updateMessage = 'Success', @updateStatus = 'Applied';	

	-- Update the scheduled change.
	EXEC vspVAUpdateScheduledChange @scheduledChangeKeyID, @updateStatus, @updateMessage, '';
	
	RETURN @returnCode;	
END





/****** Object:  StoredProcedure [dbo].[vspVPGetFormQuery]    Script Date: 12/07/2010 12:29:25 ******/
SET ANSI_NULLS ON

GO
GRANT EXECUTE ON  [dbo].[vspVAProcessScheduledChange] TO [public]
GO
