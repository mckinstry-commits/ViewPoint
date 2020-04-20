SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE VIEW [dbo].[SMServiceCenterCallType]
AS
SELECT SMAssociatedCallTypeID,SMCo,ServiceCenter,CallType FROM dbo.vSMAssociatedCallType
WHERE Division IS NULL 








GO
GRANT SELECT ON  [dbo].[SMServiceCenterCallType] TO [public]
GRANT INSERT ON  [dbo].[SMServiceCenterCallType] TO [public]
GRANT DELETE ON  [dbo].[SMServiceCenterCallType] TO [public]
GRANT UPDATE ON  [dbo].[SMServiceCenterCallType] TO [public]
GO
