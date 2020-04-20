SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create view [dbo].[udEquipAttributes] as select a.* From budEquipAttributes a
GO
GRANT SELECT ON  [dbo].[udEquipAttributes] TO [public]
GRANT INSERT ON  [dbo].[udEquipAttributes] TO [public]
GRANT DELETE ON  [dbo].[udEquipAttributes] TO [public]
GRANT UPDATE ON  [dbo].[udEquipAttributes] TO [public]
GO
