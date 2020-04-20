SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create view [dbo].[udInsurance] as select a.* From budInsurance a
GO
GRANT SELECT ON  [dbo].[udInsurance] TO [public]
GRANT INSERT ON  [dbo].[udInsurance] TO [public]
GRANT DELETE ON  [dbo].[udInsurance] TO [public]
GRANT UPDATE ON  [dbo].[udInsurance] TO [public]
GO
