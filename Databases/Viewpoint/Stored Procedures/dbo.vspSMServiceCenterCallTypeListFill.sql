SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspSMServiceCenterCallTypeListFill]
(@SMCo bCompany,@ServiceCenter varchar(10))

AS
/*Created By:  TRL 07/19/10 Issue 131640
*Modified By;
*
*Purpose List Available and Assigned CallType Records for ServiceCenter 
*/
SET NOCOUNT ON;

/*Available Call Types*/
SELECT CoCallType.CallType,CoCallType.Description FROM dbo.SMCallType CoCallType
LEFT JOIN SMServiceCenterCallType ON SMServiceCenterCallType.SMCo=CoCallType.SMCo AND SMServiceCenterCallType.CallType=CoCallType.CallType
AND SMServiceCenterCallType.ServiceCenter=@ServiceCenter
WHERE CoCallType.SMCo=@SMCo AND Active='Y' 
AND SMServiceCenterCallType.SMAssociatedCallTypeID IS NULL
ORDER BY CoCallType.CallType

/*Assigned Call Types */
SELECT CoCallType.CallType,CoCallType.Description FROM dbo.SMCallType CoCallType
INNER JOIN dbo.SMServiceCenterCallType SCCallType ON SCCallType.SMCo=CoCallType.SMCo AND SCCallType.CallType=CoCallType.CallType
WHERE CoCallType.SMCo=@SMCo AND Active='Y' AND SCCallType.ServiceCenter = @ServiceCenter 
ORDER BY CoCallType.CallType
		

GO
GRANT EXECUTE ON  [dbo].[vspSMServiceCenterCallTypeListFill] TO [public]
GO
