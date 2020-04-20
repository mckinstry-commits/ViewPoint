SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE view [dbo].[HQResponseValueItem] as select a.* From vHQResponseValueItem a


GO
GRANT SELECT ON  [dbo].[HQResponseValueItem] TO [public]
GRANT INSERT ON  [dbo].[HQResponseValueItem] TO [public]
GRANT DELETE ON  [dbo].[HQResponseValueItem] TO [public]
GRANT UPDATE ON  [dbo].[HQResponseValueItem] TO [public]
GRANT SELECT ON  [dbo].[HQResponseValueItem] TO [Viewpoint]
GRANT INSERT ON  [dbo].[HQResponseValueItem] TO [Viewpoint]
GRANT DELETE ON  [dbo].[HQResponseValueItem] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[HQResponseValueItem] TO [Viewpoint]
GO
