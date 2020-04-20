SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRED] as select a.* From bPRED a
GO
GRANT SELECT ON  [dbo].[PRED] TO [public]
GRANT INSERT ON  [dbo].[PRED] TO [public]
GRANT DELETE ON  [dbo].[PRED] TO [public]
GRANT UPDATE ON  [dbo].[PRED] TO [public]
GRANT SELECT ON  [dbo].[PRED] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRED] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRED] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRED] TO [Viewpoint]
GO
