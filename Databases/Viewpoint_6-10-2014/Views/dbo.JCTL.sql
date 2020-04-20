SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JCTL] as select a.* From bJCTL a
GO
GRANT SELECT ON  [dbo].[JCTL] TO [public]
GRANT INSERT ON  [dbo].[JCTL] TO [public]
GRANT DELETE ON  [dbo].[JCTL] TO [public]
GRANT UPDATE ON  [dbo].[JCTL] TO [public]
GRANT SELECT ON  [dbo].[JCTL] TO [Viewpoint]
GRANT INSERT ON  [dbo].[JCTL] TO [Viewpoint]
GRANT DELETE ON  [dbo].[JCTL] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[JCTL] TO [Viewpoint]
GO
