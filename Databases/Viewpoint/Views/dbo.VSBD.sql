SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[VSBD] as select a.* From bVSBD a

GO
GRANT SELECT ON  [dbo].[VSBD] TO [public]
GRANT INSERT ON  [dbo].[VSBD] TO [public]
GRANT DELETE ON  [dbo].[VSBD] TO [public]
GRANT UPDATE ON  [dbo].[VSBD] TO [public]
GO
