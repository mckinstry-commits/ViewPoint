SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[JBIDTMWork] as select a.* From bJBIDTMWork a

GO
GRANT SELECT ON  [dbo].[JBIDTMWork] TO [public]
GRANT INSERT ON  [dbo].[JBIDTMWork] TO [public]
GRANT DELETE ON  [dbo].[JBIDTMWork] TO [public]
GRANT UPDATE ON  [dbo].[JBIDTMWork] TO [public]
GO
