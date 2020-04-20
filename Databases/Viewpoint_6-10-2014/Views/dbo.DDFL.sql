SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     view [dbo].[DDFL] as select a.* From vDDFL a

GO
GRANT SELECT ON  [dbo].[DDFL] TO [public]
GRANT INSERT ON  [dbo].[DDFL] TO [public]
GRANT DELETE ON  [dbo].[DDFL] TO [public]
GRANT UPDATE ON  [dbo].[DDFL] TO [public]
GRANT SELECT ON  [dbo].[DDFL] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DDFL] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DDFL] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DDFL] TO [Viewpoint]
GO
