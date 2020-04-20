SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspSMDivisionCallTypeInsert]
(@SMCo bCompany,@ServiceCenter varchar(10),@Division varchar(10),@CallType varchar(10))
AS
/*Created By:  TRL 07/19/10 Issue 131640
*Modified By;
*
*Purpose update and delete CallType Records for ServiceCenter/Division Call Types
*/

SET NOCOUNT ON;

IF NOT EXISTS (SELECT TOP 1 1 FROM dbo.SMDivisionCallType WHERE SMCo=@SMCo AND ServiceCenter=@ServiceCenter AND Division =@Division AND CallType=@CallType)
BEGIN 
	INSERT into dbo.SMDivisionCallType (SMCo,ServiceCenter,Division,CallType)
	SELECT @SMCo, @ServiceCenter,@Division,@CallType
END


GO
GRANT EXECUTE ON  [dbo].[vspSMDivisionCallTypeInsert] TO [public]
GO
