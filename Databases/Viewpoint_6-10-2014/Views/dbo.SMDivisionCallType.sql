SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE VIEW [dbo].[SMDivisionCallType] 
AS
SELECT SMAssociatedCallTypeID,SMCo,ServiceCenter,Division,CallType FROM dbo.vSMAssociatedCallType
WHERE Division IS NOT NULL 








GO
GRANT SELECT ON  [dbo].[SMDivisionCallType] TO [public]
GRANT INSERT ON  [dbo].[SMDivisionCallType] TO [public]
GRANT DELETE ON  [dbo].[SMDivisionCallType] TO [public]
GRANT UPDATE ON  [dbo].[SMDivisionCallType] TO [public]
GRANT SELECT ON  [dbo].[SMDivisionCallType] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMDivisionCallType] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMDivisionCallType] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMDivisionCallType] TO [Viewpoint]
GO
