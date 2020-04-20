SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMWM] as select a.* From bPMWM a

GO
GRANT SELECT ON  [dbo].[PMWM] TO [public]
GRANT INSERT ON  [dbo].[PMWM] TO [public]
GRANT DELETE ON  [dbo].[PMWM] TO [public]
GRANT UPDATE ON  [dbo].[PMWM] TO [public]
GRANT SELECT ON  [dbo].[PMWM] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMWM] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMWM] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMWM] TO [Viewpoint]
GO
