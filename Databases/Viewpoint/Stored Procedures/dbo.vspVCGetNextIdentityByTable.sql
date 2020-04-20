SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jeremiah Barkley
-- Create date: 10/22/09
-- Description:	Get the next identity for a table
-- =============================================
CREATE PROCEDURE [dbo].[vspVCGetNextIdentityByTable]
(@TableName varchar(50))
AS
BEGIN
	SET NOCOUNT ON;

	SELECT IDENT_CURRENT(@TableName) + IDENT_INCR(@TableName)
END

GO
GRANT EXECUTE ON  [dbo].[vspVCGetNextIdentityByTable] TO [public]
GO
