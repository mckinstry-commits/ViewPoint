SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create view [dbo].[udEquipAttTypes] as select a.* From budEquipAttTypes a
GO
GRANT SELECT ON  [dbo].[udEquipAttTypes] TO [public]
GRANT INSERT ON  [dbo].[udEquipAttTypes] TO [public]
GRANT DELETE ON  [dbo].[udEquipAttTypes] TO [public]
GRANT UPDATE ON  [dbo].[udEquipAttTypes] TO [public]
GO
