
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[SMServiceItemPart] as select a.* From vSMServiceItemPart a
GO

GRANT SELECT ON  [dbo].[SMServiceItemPart] TO [public]
GRANT INSERT ON  [dbo].[SMServiceItemPart] TO [public]
GRANT DELETE ON  [dbo].[SMServiceItemPart] TO [public]
GRANT UPDATE ON  [dbo].[SMServiceItemPart] TO [public]
GO
