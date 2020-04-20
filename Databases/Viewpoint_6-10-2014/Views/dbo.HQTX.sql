SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HQTX] as select a.* From bHQTX a
GO
GRANT SELECT ON  [dbo].[HQTX] TO [public]
GRANT INSERT ON  [dbo].[HQTX] TO [public]
GRANT DELETE ON  [dbo].[HQTX] TO [public]
GRANT UPDATE ON  [dbo].[HQTX] TO [public]
GRANT SELECT ON  [dbo].[HQTX] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HQTX] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HQTX] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HQTX] TO [Viewpoint]
GO
