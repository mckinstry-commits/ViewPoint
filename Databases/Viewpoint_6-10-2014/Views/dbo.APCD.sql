SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[APCD] as select a.* From bAPCD a
GO
GRANT SELECT ON  [dbo].[APCD] TO [public]
GRANT INSERT ON  [dbo].[APCD] TO [public]
GRANT DELETE ON  [dbo].[APCD] TO [public]
GRANT UPDATE ON  [dbo].[APCD] TO [public]
GRANT SELECT ON  [dbo].[APCD] TO [Viewpoint]
GRANT INSERT ON  [dbo].[APCD] TO [Viewpoint]
GRANT DELETE ON  [dbo].[APCD] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[APCD] TO [Viewpoint]
GO
