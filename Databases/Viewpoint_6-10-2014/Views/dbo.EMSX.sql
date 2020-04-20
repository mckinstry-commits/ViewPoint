SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMSX] as select a.* From bEMSX a
GO
GRANT SELECT ON  [dbo].[EMSX] TO [public]
GRANT INSERT ON  [dbo].[EMSX] TO [public]
GRANT DELETE ON  [dbo].[EMSX] TO [public]
GRANT UPDATE ON  [dbo].[EMSX] TO [public]
GRANT SELECT ON  [dbo].[EMSX] TO [Viewpoint]
GRANT INSERT ON  [dbo].[EMSX] TO [Viewpoint]
GRANT DELETE ON  [dbo].[EMSX] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[EMSX] TO [Viewpoint]
GO
