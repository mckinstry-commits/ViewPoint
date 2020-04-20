SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[APVM] as select a.* From bAPVM a
GO
GRANT SELECT ON  [dbo].[APVM] TO [public]
GRANT INSERT ON  [dbo].[APVM] TO [public]
GRANT DELETE ON  [dbo].[APVM] TO [public]
GRANT UPDATE ON  [dbo].[APVM] TO [public]
GRANT SELECT ON  [dbo].[APVM] TO [Viewpoint]
GRANT INSERT ON  [dbo].[APVM] TO [Viewpoint]
GRANT DELETE ON  [dbo].[APVM] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[APVM] TO [Viewpoint]
GO
