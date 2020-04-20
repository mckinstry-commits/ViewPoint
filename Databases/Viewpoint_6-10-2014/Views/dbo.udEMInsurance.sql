SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udEMInsurance] as select a.* From budEMInsurance a
GO
GRANT SELECT ON  [dbo].[udEMInsurance] TO [public]
GRANT INSERT ON  [dbo].[udEMInsurance] TO [public]
GRANT DELETE ON  [dbo].[udEMInsurance] TO [public]
GRANT UPDATE ON  [dbo].[udEMInsurance] TO [public]
GO
