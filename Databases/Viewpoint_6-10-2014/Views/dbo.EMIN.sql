SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMIN] as select a.* From bEMIN a
GO
GRANT SELECT ON  [dbo].[EMIN] TO [public]
GRANT INSERT ON  [dbo].[EMIN] TO [public]
GRANT DELETE ON  [dbo].[EMIN] TO [public]
GRANT UPDATE ON  [dbo].[EMIN] TO [public]
GRANT SELECT ON  [dbo].[EMIN] TO [Viewpoint]
GRANT INSERT ON  [dbo].[EMIN] TO [Viewpoint]
GRANT DELETE ON  [dbo].[EMIN] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[EMIN] TO [Viewpoint]
GO
