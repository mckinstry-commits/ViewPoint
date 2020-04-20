SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HRET] as select a.* From bHRET a
GO
GRANT SELECT ON  [dbo].[HRET] TO [public]
GRANT INSERT ON  [dbo].[HRET] TO [public]
GRANT DELETE ON  [dbo].[HRET] TO [public]
GRANT UPDATE ON  [dbo].[HRET] TO [public]
GRANT SELECT ON  [dbo].[HRET] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HRET] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HRET] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HRET] TO [Viewpoint]
GO
