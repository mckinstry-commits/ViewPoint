SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HRDP] as select a.* From bHRDP a
GO
GRANT SELECT ON  [dbo].[HRDP] TO [public]
GRANT INSERT ON  [dbo].[HRDP] TO [public]
GRANT DELETE ON  [dbo].[HRDP] TO [public]
GRANT UPDATE ON  [dbo].[HRDP] TO [public]
GRANT SELECT ON  [dbo].[HRDP] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HRDP] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HRDP] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HRDP] TO [Viewpoint]
GO
