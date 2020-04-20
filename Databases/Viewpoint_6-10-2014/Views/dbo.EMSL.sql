SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMSL] as select a.* From bEMSL a
GO
GRANT SELECT ON  [dbo].[EMSL] TO [public]
GRANT INSERT ON  [dbo].[EMSL] TO [public]
GRANT DELETE ON  [dbo].[EMSL] TO [public]
GRANT UPDATE ON  [dbo].[EMSL] TO [public]
GRANT SELECT ON  [dbo].[EMSL] TO [Viewpoint]
GRANT INSERT ON  [dbo].[EMSL] TO [Viewpoint]
GRANT DELETE ON  [dbo].[EMSL] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[EMSL] TO [Viewpoint]
GO
