SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udOperatingUnit] as select a.* From budOperatingUnit a
GO
GRANT SELECT ON  [dbo].[udOperatingUnit] TO [public]
GRANT INSERT ON  [dbo].[udOperatingUnit] TO [public]
GRANT DELETE ON  [dbo].[udOperatingUnit] TO [public]
GRANT UPDATE ON  [dbo].[udOperatingUnit] TO [public]
GO
