SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMAV] as select a.* From bEMAV a
GO
GRANT SELECT ON  [dbo].[EMAV] TO [public]
GRANT INSERT ON  [dbo].[EMAV] TO [public]
GRANT DELETE ON  [dbo].[EMAV] TO [public]
GRANT UPDATE ON  [dbo].[EMAV] TO [public]
GRANT SELECT ON  [dbo].[EMAV] TO [Viewpoint]
GRANT INSERT ON  [dbo].[EMAV] TO [Viewpoint]
GRANT DELETE ON  [dbo].[EMAV] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[EMAV] TO [Viewpoint]
GO
