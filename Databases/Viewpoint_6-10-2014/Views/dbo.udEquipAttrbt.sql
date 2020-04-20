SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create view [dbo].[udEquipAttrbt] as select a.* From budEquipAttrbt a
GO
GRANT SELECT ON  [dbo].[udEquipAttrbt] TO [public]
GRANT INSERT ON  [dbo].[udEquipAttrbt] TO [public]
GRANT DELETE ON  [dbo].[udEquipAttrbt] TO [public]
GRANT UPDATE ON  [dbo].[udEquipAttrbt] TO [public]
GO
