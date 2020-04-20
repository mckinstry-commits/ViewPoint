SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HQTL] as select a.* From bHQTL a
GO
GRANT SELECT ON  [dbo].[HQTL] TO [public]
GRANT INSERT ON  [dbo].[HQTL] TO [public]
GRANT DELETE ON  [dbo].[HQTL] TO [public]
GRANT UPDATE ON  [dbo].[HQTL] TO [public]
GO
