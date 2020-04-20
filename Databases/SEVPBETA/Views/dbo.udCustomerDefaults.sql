SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udCustomerDefaults] as select a.* From budCustomerDefaults a
GO
GRANT SELECT ON  [dbo].[udCustomerDefaults] TO [public]
GRANT INSERT ON  [dbo].[udCustomerDefaults] TO [public]
GRANT DELETE ON  [dbo].[udCustomerDefaults] TO [public]
GRANT UPDATE ON  [dbo].[udCustomerDefaults] TO [public]
GO
