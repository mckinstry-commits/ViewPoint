SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.udxrefARCustomer as select a.* From Viewpoint.dbo.budxrefARCustomer a;

GO
GRANT SELECT ON  [dbo].[udxrefARCustomer] TO [public]
GRANT INSERT ON  [dbo].[udxrefARCustomer] TO [public]
GRANT DELETE ON  [dbo].[udxrefARCustomer] TO [public]
GRANT UPDATE ON  [dbo].[udxrefARCustomer] TO [public]
GO
