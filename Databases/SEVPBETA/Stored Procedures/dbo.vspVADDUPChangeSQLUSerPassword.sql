SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		KE,vspVADDUPChangeSQLUSerPassword
-- Create date: 6/13/2012
-- Description:	This proc changes a users sql password to the database
-- =============================================
create PROCEDURE [dbo].[vspVADDUPChangeSQLUSerPassword]	
	(@username varchar(40), @password varchar(50) = @username)
WITH EXECUTE AS 'viewpointcs'
AS
BEGIN
	SET NOCOUNT ON;
	
	IF EXISTS (SELECT loginname FROM master.dbo.syslogins where name = @username)
	BEGIN 
	
		DECLARE @SQL NVARCHAR(1000)
		
		SET @SQL = 'ALTER LOGIN ' + quotename(@username) + ' WITH PASSWORD = ' +quotename(@password, '''')
						
		EXECUTE(@SQL)
	END
	
END

GO
GRANT EXECUTE ON  [dbo].[vspVADDUPChangeSQLUSerPassword] TO [public]
GO
