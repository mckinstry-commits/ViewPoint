SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[SLIA] as select a.* From bSLIA a
GO
GRANT SELECT ON  [dbo].[SLIA] TO [public]
GRANT INSERT ON  [dbo].[SLIA] TO [public]
GRANT DELETE ON  [dbo].[SLIA] TO [public]
GRANT UPDATE ON  [dbo].[SLIA] TO [public]
GRANT SELECT ON  [dbo].[SLIA] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SLIA] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SLIA] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SLIA] TO [Viewpoint]
GO
