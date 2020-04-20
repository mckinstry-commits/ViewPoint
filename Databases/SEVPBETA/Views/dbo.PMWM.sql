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
GO
