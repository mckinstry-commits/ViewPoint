SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE view [dbo].[HQResponseValue] as select a.* From vHQResponseValue a


GO
GRANT SELECT ON  [dbo].[HQResponseValue] TO [public]
GRANT INSERT ON  [dbo].[HQResponseValue] TO [public]
GRANT DELETE ON  [dbo].[HQResponseValue] TO [public]
GRANT UPDATE ON  [dbo].[HQResponseValue] TO [public]
GRANT SELECT ON  [dbo].[HQResponseValue] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HQResponseValue] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HQResponseValue] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HQResponseValue] TO [Viewpoint]
GO
