SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[RPUP] as select a.* From vRPUP a
GO
GRANT SELECT ON  [dbo].[RPUP] TO [public]
GRANT INSERT ON  [dbo].[RPUP] TO [public]
GRANT DELETE ON  [dbo].[RPUP] TO [public]
GRANT UPDATE ON  [dbo].[RPUP] TO [public]
GRANT SELECT ON  [dbo].[RPUP] TO [Viewpoint]
GRANT INSERT ON  [dbo].[RPUP] TO [Viewpoint]
GRANT DELETE ON  [dbo].[RPUP] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[RPUP] TO [Viewpoint]
GO
