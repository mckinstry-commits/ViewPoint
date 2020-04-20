SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[SMCustomer] as select a.* From vSMCustomer a
GO
GRANT SELECT ON  [dbo].[SMCustomer] TO [public]
GRANT INSERT ON  [dbo].[SMCustomer] TO [public]
GRANT DELETE ON  [dbo].[SMCustomer] TO [public]
GRANT UPDATE ON  [dbo].[SMCustomer] TO [public]
GO
