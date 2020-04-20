SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HRED] as select a.* From bHRED a
GO
GRANT SELECT ON  [dbo].[HRED] TO [public]
GRANT INSERT ON  [dbo].[HRED] TO [public]
GRANT DELETE ON  [dbo].[HRED] TO [public]
GRANT UPDATE ON  [dbo].[HRED] TO [public]
GRANT SELECT ON  [dbo].[HRED] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HRED] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HRED] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HRED] TO [Viewpoint]
GO
