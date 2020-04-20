SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		KE,vspVADDUPCheckIfConnectsUserExists
-- Create date: 6/14/2012
-- Description:	This proc checks the database to see if a login exists
-- =============================================
CREATE PROCEDURE [dbo].[vspVADDUPCheckIfConnectsUserExists]	
	(@username varchar(40))
WITH EXECUTE AS 'viewpointcs'
AS
BEGIN
	SET NOCOUNT ON;
	
	IF EXISTS (SELECT [VPUserName] FROM [pUsers] where [VPUserName] = @username)
	select 'Y'
	Else
	select 'N'
	
END

GO
GRANT EXECUTE ON  [dbo].[vspVADDUPCheckIfConnectsUserExists] TO [public]
GO
