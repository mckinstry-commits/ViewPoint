SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspSMDivisionCallTypeDelete]
(@SMCo bCompany,@ServiceCenter varchar(10),@Division varchar(10),@CallType varchar(10))
AS
/*Created By:  TRL 07/19/10 Issue 131640
*Modified By;
*
*Purpose  delete CallType Records for ServiceCenter/Division Call Types
*/

SET NOCOUNT ON;

IF EXISTS (SELECT TOP 1 1 FROM dbo.SMDivisionCallType WHERE SMCo=@SMCo AND ServiceCenter=@ServiceCenter AND Division =@Division AND CallType=@CallType)
BEGIN
	DELETE FROM dbo.SMDivisionCallType WHERE SMCo=@SMCo AND ServiceCenter=@ServiceCenter AND Division =@Division AND CallType=@CallType
END


GO
GRANT EXECUTE ON  [dbo].[vspSMDivisionCallTypeDelete] TO [public]
GO
