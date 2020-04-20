SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[APVA] as select a.* From bAPVA a
GO
GRANT SELECT ON  [dbo].[APVA] TO [public]
GRANT INSERT ON  [dbo].[APVA] TO [public]
GRANT DELETE ON  [dbo].[APVA] TO [public]
GRANT UPDATE ON  [dbo].[APVA] TO [public]
GRANT SELECT ON  [dbo].[APVA] TO [Viewpoint]
GRANT INSERT ON  [dbo].[APVA] TO [Viewpoint]
GRANT DELETE ON  [dbo].[APVA] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[APVA] TO [Viewpoint]
GO
