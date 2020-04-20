SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[IMXF] as select a.* From bIMXF a

GO
GRANT SELECT ON  [dbo].[IMXF] TO [public]
GRANT INSERT ON  [dbo].[IMXF] TO [public]
GRANT DELETE ON  [dbo].[IMXF] TO [public]
GRANT UPDATE ON  [dbo].[IMXF] TO [public]
GRANT SELECT ON  [dbo].[IMXF] TO [Viewpoint]
GRANT INSERT ON  [dbo].[IMXF] TO [Viewpoint]
GRANT DELETE ON  [dbo].[IMXF] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[IMXF] TO [Viewpoint]
GO
