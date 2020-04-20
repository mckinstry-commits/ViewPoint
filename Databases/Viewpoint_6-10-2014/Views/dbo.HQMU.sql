SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HQMU] as select a.* From bHQMU a

GO
GRANT SELECT ON  [dbo].[HQMU] TO [public]
GRANT INSERT ON  [dbo].[HQMU] TO [public]
GRANT DELETE ON  [dbo].[HQMU] TO [public]
GRANT UPDATE ON  [dbo].[HQMU] TO [public]
GRANT SELECT ON  [dbo].[HQMU] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HQMU] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HQMU] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HQMU] TO [Viewpoint]
GO
