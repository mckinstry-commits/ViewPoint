SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMJC] as select a.* From bEMJC a
GO
GRANT SELECT ON  [dbo].[EMJC] TO [public]
GRANT INSERT ON  [dbo].[EMJC] TO [public]
GRANT DELETE ON  [dbo].[EMJC] TO [public]
GRANT UPDATE ON  [dbo].[EMJC] TO [public]
GRANT SELECT ON  [dbo].[EMJC] TO [Viewpoint]
GRANT INSERT ON  [dbo].[EMJC] TO [Viewpoint]
GRANT DELETE ON  [dbo].[EMJC] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[EMJC] TO [Viewpoint]
GO
