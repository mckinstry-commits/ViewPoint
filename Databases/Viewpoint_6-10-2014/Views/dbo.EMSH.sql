SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMSH] as select a.* From bEMSH a
GO
GRANT SELECT ON  [dbo].[EMSH] TO [public]
GRANT INSERT ON  [dbo].[EMSH] TO [public]
GRANT DELETE ON  [dbo].[EMSH] TO [public]
GRANT UPDATE ON  [dbo].[EMSH] TO [public]
GRANT SELECT ON  [dbo].[EMSH] TO [Viewpoint]
GRANT INSERT ON  [dbo].[EMSH] TO [Viewpoint]
GRANT DELETE ON  [dbo].[EMSH] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[EMSH] TO [Viewpoint]
GO
