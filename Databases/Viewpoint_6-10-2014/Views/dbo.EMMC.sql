SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMMC] as select a.* From bEMMC a
GO
GRANT SELECT ON  [dbo].[EMMC] TO [public]
GRANT INSERT ON  [dbo].[EMMC] TO [public]
GRANT DELETE ON  [dbo].[EMMC] TO [public]
GRANT UPDATE ON  [dbo].[EMMC] TO [public]
GRANT SELECT ON  [dbo].[EMMC] TO [Viewpoint]
GRANT INSERT ON  [dbo].[EMMC] TO [Viewpoint]
GRANT DELETE ON  [dbo].[EMMC] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[EMMC] TO [Viewpoint]
GO
