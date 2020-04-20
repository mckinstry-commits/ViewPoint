SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[SMCustomerContact] as select a.* From vSMCustomerContact a




GO
GRANT SELECT ON  [dbo].[SMCustomerContact] TO [public]
GRANT INSERT ON  [dbo].[SMCustomerContact] TO [public]
GRANT DELETE ON  [dbo].[SMCustomerContact] TO [public]
GRANT UPDATE ON  [dbo].[SMCustomerContact] TO [public]
GO
