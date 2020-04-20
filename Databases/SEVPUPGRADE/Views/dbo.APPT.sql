SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[APPT] as select a.* From bAPPT a
GO
GRANT SELECT ON  [dbo].[APPT] TO [public]
GRANT INSERT ON  [dbo].[APPT] TO [public]
GRANT DELETE ON  [dbo].[APPT] TO [public]
GRANT UPDATE ON  [dbo].[APPT] TO [public]
GO
