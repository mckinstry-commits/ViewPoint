SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author: JonathanP 08/13/07 - Created.
--		 
--
-- Description:	This stored procedure will create or alter UD stored procedures.
-- =============================================
CREATE PROCEDURE [dbo].[vspUDCreateAlterStoredProcedure]
	(@theStoredProcedureName as varchar(60), @theStoredProcedureCode as varchar(7900), 
	 @theErrorMessage as varchar(255) output) with execute as 'viewpointcs'
AS
BEGIN	
	SET NOCOUNT ON;
	
	declare @returnCode as int, @dynamicSQL as varchar(8000)
	select @returnCode = 0

	-- Check if a name was given for the stored procedure.
	if @theStoredProcedureName is null
	begin
		select @theErrorMessage = 'The stored procedure name is null.', @returnCode = 1
		goto vspExit
	end

	-- Check if code was given for the stored procedure.
	if @theStoredProcedureCode is null
	begin
		select @theErrorMessage = 'The stored procedure code is null.', @returnCode = 1
		goto vspExit
	end

	--Get the number of times @theStoredProcedureName exists in the database.
	select name from sysobjects where name = @theStoredProcedureName
	
	-- If the row count is 0, the procedure does not exist and needs to be created. If the row count is not zero, that means
	-- the procedure exists, we when should alter it.
	if @@ROWCOUNT = 0
	begin		
		select @dynamicSQL = 'create procedure ' + @theStoredProcedureName + ' ' + @theStoredProcedureCode
	end
	else
		select @dynamicSQL = 'alter procedure ' + @theStoredProcedureName + ' ' + @theStoredProcedureCode		

	-- Create/Alter the stored procedure.
	exec (@dynamicSQL)		

	-- Build SQL statement to grant permissions to public for the stored procedure.
	select @dynamicSQL = 'grant execute on ' + @theStoredProcedureName + ' to public'

	-- Grant execute permissions.
	exec (@dynamicSQL)		

vspExit:
	return @returnCode		
	
END

GO
GRANT EXECUTE ON  [dbo].[vspUDCreateAlterStoredProcedure] TO [public]
GO
