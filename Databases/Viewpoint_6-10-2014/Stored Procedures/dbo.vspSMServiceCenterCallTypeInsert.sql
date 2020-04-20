SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspSMServiceCenterCallTypeInsert]
(@SMCo bCompany,@ServiceCenter varchar(10),@CallType varchar(10))
AS
/*Created By:  TRL 07/19/10 Issue 131640
*Modified By;
*
*Purpose Insert CallType Records for ServiceCenter Call Types
*/
SET NOCOUNT ON;

IF NOT EXISTS (SELECT TOP 1 1 FROM dbo.SMServiceCenterCallType WHERE SMCo=@SMCo AND ServiceCenter=@ServiceCenter AND CallType=@CallType)
BEGIN
	INSERT INTO dbo.SMServiceCenterCallType (SMCo,ServiceCenter,CallType)
	SELECT @SMCo,@ServiceCenter,@CallType
END
		

GO
GRANT EXECUTE ON  [dbo].[vspSMServiceCenterCallTypeInsert] TO [public]
GO
