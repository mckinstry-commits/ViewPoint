SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[ARBL] as select a.* From bARBL a
GO
GRANT SELECT ON  [dbo].[ARBL] TO [public]
GRANT INSERT ON  [dbo].[ARBL] TO [public]
GRANT DELETE ON  [dbo].[ARBL] TO [public]
GRANT UPDATE ON  [dbo].[ARBL] TO [public]
GRANT SELECT ON  [dbo].[ARBL] TO [Viewpoint]
GRANT INSERT ON  [dbo].[ARBL] TO [Viewpoint]
GRANT DELETE ON  [dbo].[ARBL] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[ARBL] TO [Viewpoint]
GO
