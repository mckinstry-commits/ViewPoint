SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<AL, vspDDMOIsModuleActive>
-- Create date: <10/4/2007>
-- Description:	Checks if the Module passed in is active and available
-- =============================================
CREATE PROCEDURE [dbo].[vspDDMOIsModuleActive]
	-- Add the parameters for the stored procedure here
	(@rcode TINYINT = 0, @mod char(2), @errmsg varchar(512) OUTPUT  )
AS
BEGIN

declare @modliclevel tinyint

SET NOCOUNT ON

--make sure module exists
SELECT m.[Mod]
FROM [vDDMO] m
WHERE [Mod] = @mod
if @@rowcount = 0 
	begin
	select @errmsg = 'Module does not exist!', @rcode = 1
	goto vspexit
	END

-- make sure the forms' primary module is active and check license level
select @mod = m.Mod, @modliclevel = m.LicLevel
from dbo.vDDMO m (nolock)
WHERE @mod = m.[Mod] AND m.Active = 'Y'
if @@rowcount = 0 
	begin
	select @errmsg = 'Module is not active!', @rcode = 1
	goto vspexit
	end

vspexit:
	if @rcode <> 0 select @errmsg = @errmsg + char(13) + char(10) + '[vspDDMOIsModuleActive]'
	return @rcode

END

GO
GRANT EXECUTE ON  [dbo].[vspDDMOIsModuleActive] TO [public]
GO
