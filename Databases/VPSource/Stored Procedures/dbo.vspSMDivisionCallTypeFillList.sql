SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[vspSMDivisionCallTypeFillList]
(@SMCo bCompany,@ServiceCenter varchar(10),@Division varchar(10))

AS
/*Created By:  TRL 07/19/10 Issue 131640
*Modified By;
*
*Purpose List Available and Assigned CallType Records for ServiceCenter/Division
*/
SET NOCOUNT ON;

/*Available Call Types*/
SELECT SMCallType.CallType,SMCallType.Description FROM dbo.SMCallType 
LEFT JOIN SMDivisionCallType ON SMDivisionCallType.SMCo=SMCallType.SMCo AND SMDivisionCallType.CallType=SMCallType.CallType
AND SMDivisionCallType.ServiceCenter=@ServiceCenter AND SMDivisionCallType.Division=@Division 
WHERE SMCallType.SMCo=@SMCo AND SMCallType.Active='Y' 
AND SMDivisionCallType.SMAssociatedCallTypeID IS NULL 
ORDER BY SMCallType.CallType ASC;  

/*Assigned Call Types */
SELECT SMCallType.CallType,SMCallType.Description FROM dbo.SMCallType 
INNER JOIN dbo.SMDivisionCallType  ON SMDivisionCallType.SMCo=SMCallType.SMCo AND SMDivisionCallType.CallType=SMCallType.CallType
WHERE SMCallType.SMCo=@SMCo AND SMCallType.Active='Y' AND SMDivisionCallType.ServiceCenter = @ServiceCenter AND SMDivisionCallType.Division=@Division
ORDER BY SMCallType.CallType ASC;  
		
--GO
--	DROP PROCEDURE dbo.vspSMCallTypesFillList 
--GO
--	DROP PROCEDURE dbo.vspSMCallTypeUpdateList 

GO
GRANT EXECUTE ON  [dbo].[vspSMDivisionCallTypeFillList] TO [public]
GO
