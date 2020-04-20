SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HRCC] as select a.* From bHRCC a

GO
GRANT SELECT ON  [dbo].[HRCC] TO [public]
GRANT INSERT ON  [dbo].[HRCC] TO [public]
GRANT DELETE ON  [dbo].[HRCC] TO [public]
GRANT UPDATE ON  [dbo].[HRCC] TO [public]
GO
