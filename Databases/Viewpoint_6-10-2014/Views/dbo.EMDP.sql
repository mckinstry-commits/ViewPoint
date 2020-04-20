SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMDP] as select a.* From bEMDP a
GO
GRANT SELECT ON  [dbo].[EMDP] TO [public]
GRANT INSERT ON  [dbo].[EMDP] TO [public]
GRANT DELETE ON  [dbo].[EMDP] TO [public]
GRANT UPDATE ON  [dbo].[EMDP] TO [public]
GRANT SELECT ON  [dbo].[EMDP] TO [Viewpoint]
GRANT INSERT ON  [dbo].[EMDP] TO [Viewpoint]
GRANT DELETE ON  [dbo].[EMDP] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[EMDP] TO [Viewpoint]
GO
