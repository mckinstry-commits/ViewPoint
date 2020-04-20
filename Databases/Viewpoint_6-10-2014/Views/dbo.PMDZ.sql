SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMDZ] as select a.* From bPMDZ a



GO
GRANT SELECT ON  [dbo].[PMDZ] TO [public]
GRANT INSERT ON  [dbo].[PMDZ] TO [public]
GRANT DELETE ON  [dbo].[PMDZ] TO [public]
GRANT UPDATE ON  [dbo].[PMDZ] TO [public]
GRANT SELECT ON  [dbo].[PMDZ] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PMDZ] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PMDZ] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PMDZ] TO [Viewpoint]
GO
