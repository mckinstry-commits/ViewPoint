SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create view [dbo].[udEquipmentUpfitting] as select a.* From budEquipmentUpfitting a
GO
GRANT SELECT ON  [dbo].[udEquipmentUpfitting] TO [public]
GRANT INSERT ON  [dbo].[udEquipmentUpfitting] TO [public]
GRANT DELETE ON  [dbo].[udEquipmentUpfitting] TO [public]
GRANT UPDATE ON  [dbo].[udEquipmentUpfitting] TO [public]
GO
