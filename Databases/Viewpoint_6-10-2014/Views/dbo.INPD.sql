SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[INPD] as select a.* From bINPD a
GO
GRANT SELECT ON  [dbo].[INPD] TO [public]
GRANT INSERT ON  [dbo].[INPD] TO [public]
GRANT DELETE ON  [dbo].[INPD] TO [public]
GRANT UPDATE ON  [dbo].[INPD] TO [public]
GRANT SELECT ON  [dbo].[INPD] TO [Viewpoint]
GRANT INSERT ON  [dbo].[INPD] TO [Viewpoint]
GRANT DELETE ON  [dbo].[INPD] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[INPD] TO [Viewpoint]
GO
