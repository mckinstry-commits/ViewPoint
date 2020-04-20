SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udShipMethod] as select a.* From budShipMethod a
GO
GRANT SELECT ON  [dbo].[udShipMethod] TO [public]
GRANT INSERT ON  [dbo].[udShipMethod] TO [public]
GRANT DELETE ON  [dbo].[udShipMethod] TO [public]
GRANT UPDATE ON  [dbo].[udShipMethod] TO [public]
GO
