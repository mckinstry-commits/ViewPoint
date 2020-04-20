SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udInsurance] as select a.* From budInsurance a
GO
GRANT SELECT ON  [dbo].[udInsurance] TO [public]
GRANT INSERT ON  [dbo].[udInsurance] TO [public]
GRANT DELETE ON  [dbo].[udInsurance] TO [public]
GRANT UPDATE ON  [dbo].[udInsurance] TO [public]
GRANT SELECT ON  [dbo].[udInsurance] TO [Viewpoint]
GRANT INSERT ON  [dbo].[udInsurance] TO [Viewpoint]
GRANT DELETE ON  [dbo].[udInsurance] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[udInsurance] TO [Viewpoint]
GO
