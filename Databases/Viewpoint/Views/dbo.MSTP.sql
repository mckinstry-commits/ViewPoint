SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[MSTP] as select a.* From bMSTP a

GO
GRANT SELECT ON  [dbo].[MSTP] TO [public]
GRANT INSERT ON  [dbo].[MSTP] TO [public]
GRANT DELETE ON  [dbo].[MSTP] TO [public]
GRANT UPDATE ON  [dbo].[MSTP] TO [public]
GO
