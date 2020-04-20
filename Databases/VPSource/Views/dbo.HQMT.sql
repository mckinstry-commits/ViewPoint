SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HQMT] as select a.* From bHQMT a
GO
GRANT SELECT ON  [dbo].[HQMT] TO [public]
GRANT INSERT ON  [dbo].[HQMT] TO [public]
GRANT DELETE ON  [dbo].[HQMT] TO [public]
GRANT UPDATE ON  [dbo].[HQMT] TO [public]
GO
