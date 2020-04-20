SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[IMWM] as select a.* From bIMWM a

GO
GRANT SELECT ON  [dbo].[IMWM] TO [public]
GRANT INSERT ON  [dbo].[IMWM] TO [public]
GRANT DELETE ON  [dbo].[IMWM] TO [public]
GRANT UPDATE ON  [dbo].[IMWM] TO [public]
GO
