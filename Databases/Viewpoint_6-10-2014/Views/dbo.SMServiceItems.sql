SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[SMServiceItems] as select a.* From vSMServiceItems a
GO
GRANT SELECT ON  [dbo].[SMServiceItems] TO [public]
GRANT INSERT ON  [dbo].[SMServiceItems] TO [public]
GRANT DELETE ON  [dbo].[SMServiceItems] TO [public]
GRANT UPDATE ON  [dbo].[SMServiceItems] TO [public]
GRANT SELECT ON  [dbo].[SMServiceItems] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMServiceItems] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMServiceItems] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMServiceItems] TO [Viewpoint]
GO
