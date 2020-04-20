SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    view [dbo].[DDWL] as select a.* From vDDWL a

GO
GRANT SELECT ON  [dbo].[DDWL] TO [public]
GRANT INSERT ON  [dbo].[DDWL] TO [public]
GRANT DELETE ON  [dbo].[DDWL] TO [public]
GRANT UPDATE ON  [dbo].[DDWL] TO [public]
GO
