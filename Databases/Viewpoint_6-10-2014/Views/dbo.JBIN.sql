SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JBIN] as select a.* From bJBIN a
GO
GRANT SELECT ON  [dbo].[JBIN] TO [public]
GRANT INSERT ON  [dbo].[JBIN] TO [public]
GRANT DELETE ON  [dbo].[JBIN] TO [public]
GRANT UPDATE ON  [dbo].[JBIN] TO [public]
GRANT SELECT ON  [dbo].[JBIN] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JBIN] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JBIN] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JBIN] TO [Viewpoint]
GO
