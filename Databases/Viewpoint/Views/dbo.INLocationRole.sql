SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[INLocationRole] as select a.* From vINLocationRole a

GO
GRANT SELECT ON  [dbo].[INLocationRole] TO [public]
GRANT INSERT ON  [dbo].[INLocationRole] TO [public]
GRANT DELETE ON  [dbo].[INLocationRole] TO [public]
GRANT UPDATE ON  [dbo].[INLocationRole] TO [public]
GO
