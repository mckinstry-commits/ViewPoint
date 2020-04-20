SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<JG, vspHQApprovalModuleIsModuleActive>
-- Create date: <3/20/2007>
-- Description:	Checks if the Module passed in is active and available
-- =============================================
CREATE PROCEDURE [dbo].[vspHQApprovalModuleIsModuleActive]
	-- Add the parameters for the stored procedure here
	(@mod char(2), @errmsg varchar(512) OUTPUT  )
AS
BEGIN

declare @rcode TINYINT, @modliclevel tinyint

SET NOCOUNT ON

--make sure module exists
SELECT m.[Mod]
FROM [vHQApprovalModule] m
WHERE [Mod] = @mod
if @@rowcount = 0 
	begin
	select @errmsg = 'Module does not exist or is not available for HQ Approval Process!', @rcode = 1
	goto vspexit
	END

EXEC @rcode = vspDDMOIsModuleActive
	 @rcode = @rcode,
	 @mod = @mod,
	 @errmsg = @errmsg OUTPUT

vspexit:
	if @rcode <> 0 select @errmsg = @errmsg + char(13) + char(10) + '[vspHQApprovalModuleIsModuleActive]'
	return @rcode

END

GO
GRANT EXECUTE ON  [dbo].[vspHQApprovalModuleIsModuleActive] TO [public]
GO
