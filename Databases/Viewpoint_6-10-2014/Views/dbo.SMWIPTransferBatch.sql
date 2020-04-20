SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[SMWIPTransferBatch] as select a.* From vSMWIPTransferBatch a
GO
GRANT SELECT ON  [dbo].[SMWIPTransferBatch] TO [public]
GRANT INSERT ON  [dbo].[SMWIPTransferBatch] TO [public]
GRANT DELETE ON  [dbo].[SMWIPTransferBatch] TO [public]
GRANT UPDATE ON  [dbo].[SMWIPTransferBatch] TO [public]
GRANT SELECT ON  [dbo].[SMWIPTransferBatch] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMWIPTransferBatch] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMWIPTransferBatch] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMWIPTransferBatch] TO [Viewpoint]
GO
