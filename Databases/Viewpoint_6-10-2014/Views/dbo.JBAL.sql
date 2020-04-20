SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JBAL] as select a.* From bJBAL a
GO
GRANT SELECT ON  [dbo].[JBAL] TO [public]
GRANT INSERT ON  [dbo].[JBAL] TO [public]
GRANT DELETE ON  [dbo].[JBAL] TO [public]
GRANT UPDATE ON  [dbo].[JBAL] TO [public]
GRANT SELECT ON  [dbo].[JBAL] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JBAL] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JBAL] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JBAL] TO [Viewpoint]
GO
