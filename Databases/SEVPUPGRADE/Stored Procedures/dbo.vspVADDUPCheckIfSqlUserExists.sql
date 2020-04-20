SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		KE,vspVADDUPCheckIfSqlUserExists
-- Create date: 6/13/2012
-- Description:	This proc checks the database to see if a login exists
-- =============================================
create PROCEDURE [dbo].[vspVADDUPCheckIfSqlUserExists]	
	(@username varchar(40))
WITH EXECUTE AS 'viewpointcs'
AS
BEGIN
	SET NOCOUNT ON;
	
	IF EXISTS (SELECT loginname FROM master.dbo.syslogins where name = @username)
	select 'Y'
	Else
	select 'N'
	
END

GO
GRANT EXECUTE ON  [dbo].[vspVADDUPCheckIfSqlUserExists] TO [public]
GO
