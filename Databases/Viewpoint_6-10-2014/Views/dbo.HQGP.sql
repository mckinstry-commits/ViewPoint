SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HQGP] as select a.* From bHQGP a
GO
GRANT SELECT ON  [dbo].[HQGP] TO [public]
GRANT INSERT ON  [dbo].[HQGP] TO [public]
GRANT DELETE ON  [dbo].[HQGP] TO [public]
GRANT UPDATE ON  [dbo].[HQGP] TO [public]
GRANT SELECT ON  [dbo].[HQGP] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HQGP] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HQGP] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HQGP] TO [Viewpoint]
GO
