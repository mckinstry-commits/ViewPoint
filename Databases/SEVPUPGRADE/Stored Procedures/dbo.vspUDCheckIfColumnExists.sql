SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author: JonathanP 01/14/08 - Created.
--		 
--
-- Description:	This stored procedure will check if a given column exists in a table. Used for validation.
-- 
-- Return Codes:
--		0 : Column exists.
--		1 : Column does not exist.
-- =============================================
CREATE PROCEDURE [dbo].[vspUDCheckIfColumnExists]
	(@tableName as varchar(20), 
	 @columnName as varchar(30), 
	 @errorMessage as varchar(255) output) with execute as 'viewpointcs'
AS
BEGIN	
	SET NOCOUNT ON;
	
	declare @returnCode as int 
	select @returnCode = 0

	select top 1 1 from INFORMATION_SCHEMA.COLUMNS 
	where TABLE_NAME = @tableName and COLUMN_NAME = @columnName
		
	-- Set the return code.
	if @@rowcount = 1
	begin
		select @returnCode = 0		
	end		
		
	if @@rowcount = 0
	begin
		select @returnCode = 1		
	end	

	return @returnCode			
END

GO
GRANT EXECUTE ON  [dbo].[vspUDCheckIfColumnExists] TO [public]
GO
