SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		DW,vspVADDUPCheckIfSqlViewpointUserExists
-- Create date: 12/19/2012
-- Description:	This proc checks the database to see if a database user exists.  This is different then the login
-- =============================================
CREATE PROCEDURE [dbo].[vspVADDUPCheckIfSqlViewpointUserExists]	
	(@username varchar(40))
WITH EXECUTE AS 'viewpointcs'
AS
BEGIN
	SET NOCOUNT ON;
	IF EXISTS (SELECT name from sysusers where name=@username)
    BEGIN
       select 'Y'
    END
    ELSE
    BEGIN
       select 'N'
    END
	
END

GO
GRANT EXECUTE ON  [dbo].[vspVADDUPCheckIfSqlViewpointUserExists] TO [public]
GO
