SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE VIEW [dbo].[SMWIPTransferBatch]
AS
SELECT a.* FROM dbo.vSMWIPTransferBatch a


GO
GRANT SELECT ON  [dbo].[SMWIPTransferBatch] TO [public]
GRANT INSERT ON  [dbo].[SMWIPTransferBatch] TO [public]
GRANT DELETE ON  [dbo].[SMWIPTransferBatch] TO [public]
GRANT UPDATE ON  [dbo].[SMWIPTransferBatch] TO [public]
GO
