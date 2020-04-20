SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[SMPayType] as select a.* From vSMPayType a
GO
GRANT SELECT ON  [dbo].[SMPayType] TO [public]
GRANT INSERT ON  [dbo].[SMPayType] TO [public]
GRANT DELETE ON  [dbo].[SMPayType] TO [public]
GRANT UPDATE ON  [dbo].[SMPayType] TO [public]
GRANT SELECT ON  [dbo].[SMPayType] TO [Viewpoint]
GRANT INSERT ON  [dbo].[SMPayType] TO [Viewpoint]
GRANT DELETE ON  [dbo].[SMPayType] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[SMPayType] TO [Viewpoint]
GO
