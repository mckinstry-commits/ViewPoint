SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udBillTypes] as select a.* From budBillTypes a
GO
GRANT SELECT ON  [dbo].[udBillTypes] TO [public]
GRANT INSERT ON  [dbo].[udBillTypes] TO [public]
GRANT DELETE ON  [dbo].[udBillTypes] TO [public]
GRANT UPDATE ON  [dbo].[udBillTypes] TO [public]
GO
