SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMTF] as select a.* From bEMTF a
GO
GRANT SELECT ON  [dbo].[EMTF] TO [public]
GRANT INSERT ON  [dbo].[EMTF] TO [public]
GRANT DELETE ON  [dbo].[EMTF] TO [public]
GRANT UPDATE ON  [dbo].[EMTF] TO [public]
GRANT SELECT ON  [dbo].[EMTF] TO [Viewpoint]
GRANT INSERT ON  [dbo].[EMTF] TO [Viewpoint]
GRANT DELETE ON  [dbo].[EMTF] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[EMTF] TO [Viewpoint]
GO
