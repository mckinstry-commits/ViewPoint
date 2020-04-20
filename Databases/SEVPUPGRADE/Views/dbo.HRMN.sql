SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HRMN] as select a.* From bHRMN a

GO
GRANT SELECT ON  [dbo].[HRMN] TO [public]
GRANT INSERT ON  [dbo].[HRMN] TO [public]
GRANT DELETE ON  [dbo].[HRMN] TO [public]
GRANT UPDATE ON  [dbo].[HRMN] TO [public]
GO
