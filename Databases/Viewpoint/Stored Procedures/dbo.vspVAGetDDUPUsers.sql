SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		AL, vspVAGetDDUPUsers
-- Create date: 7/25/08
-- Description:	returns all DDUP users
-- =============================================
CREATE PROCEDURE [dbo].[vspVAGetDDUPUsers] 
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT VPUserName FROM DDUP (nolock) order by VPUserName
	
END

GO
GRANT EXECUTE ON  [dbo].[vspVAGetDDUPUsers] TO [public]
GO
