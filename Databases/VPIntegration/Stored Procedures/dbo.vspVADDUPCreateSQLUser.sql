SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		AL,VADDUPCreateSQLUSer
-- Modified By: DW 12/19/2012 - D-04005 Move the 'create user' out of the 'NOT EXISTS' block
-- Create date: 09/06/2011
-- Description:	This proc adds a user to the database
-- =============================================
CREATE PROCEDURE [dbo].[vspVADDUPCreateSQLUser]
	-- Add the parameters for the stored procedure here
	(@username varchar(40), @password varchar(50) = @username)
WITH EXECUTE AS 'viewpointcs'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	IF NOT EXISTS (SELECT loginname FROM master.dbo.syslogins where name = @username)
	BEGIN 
	
		DECLARE @SQL NVARCHAR(1000)
		
		SET @SQL = 'CREATE LOGIN ' + quotename(@username) + ' WITH PASSWORD = ' +quotename(@password, '''') + ', DEFAULT_DATABASE = ' + quotename(DB_NAME())
		
		EXECUTE(@SQL)
		
		
	END
	
	SET @SQL = 'create user [' + @username + '] from login [' +@username + ']';
		
	EXECUTE(@SQL)
	
END
GO
GRANT EXECUTE ON  [dbo].[vspVADDUPCreateSQLUser] TO [public]
GO
