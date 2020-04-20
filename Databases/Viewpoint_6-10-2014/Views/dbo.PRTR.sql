SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRTR] as select a.* From bPRTR a
GO
GRANT SELECT ON  [dbo].[PRTR] TO [public]
GRANT INSERT ON  [dbo].[PRTR] TO [public]
GRANT DELETE ON  [dbo].[PRTR] TO [public]
GRANT UPDATE ON  [dbo].[PRTR] TO [public]
GRANT SELECT ON  [dbo].[PRTR] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRTR] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRTR] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRTR] TO [Viewpoint]
GO
