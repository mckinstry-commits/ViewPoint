SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspHQDropAuditTriggers]
/***********************************************************************
*	Created by: 	CC 05/07/2009 - Stored procedure to drop automatically generate audit triggers
*	Checked by:		JonathanP 5/22/2009
* 
*	Altered by: 	
*							
*	Usage:			TableName is the name of the table to drop the triggers on
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
		, @SchemaName						NCHAR(3)
		, @InsertTriggerName				NVARCHAR(128)
		, @UpdateTriggerName				NVARCHAR(128)
		, @DeleteTriggerName				NVARCHAR(128)
		, @NewLine							NCHAR(2)
		, @Quote							NCHAR(1)		
	   ;

	SET @SchemaName = N'dbo';
	SELECT	  
			  @InsertTriggerName = @SchemaName + N'.vt' + @TableName + N'_Audit_Insert'
			, @UpdateTriggerName = @SchemaName + N'.vt' + @TableName + N'_Audit_Update'
			, @DeleteTriggerName = @SchemaName + N'.vt' + @TableName + N'_Audit_Delete'
			, @NewLine = Char(13) + Char(10)
			, @Quote = N''''
			;			
	------------------------------------------------------	

	-------------------Drop triggers----------------------
		SET @SQL =	N'IF (OBJECT_ID(' + @Quote + @InsertTriggerName + @Quote + N', ''TR'') IS NOT NULL)' + @NewLine
					+ N'	DROP TRIGGER ' + @InsertTriggerName;
		EXEC (@SQL);

		SET @SQL =	N'IF (OBJECT_ID(' + @Quote + @UpdateTriggerName + @Quote + N', ''TR'') IS NOT NULL)' + @NewLine	   
					+ N'	DROP TRIGGER ' + @UpdateTriggerName;
		EXEC (@SQL);

		SET @SQL =	N'IF (OBJECT_ID(' + @Quote + @DeleteTriggerName + @Quote + N', ''TR'') IS NOT NULL)' + @NewLine
					+ N'	DROP TRIGGER ' + @DeleteTriggerName;
		EXEC (@SQL);

	------------------------------------------------------
END
GO
GRANT EXECUTE ON  [dbo].[vspHQDropAuditTriggers] TO [public]
GO
