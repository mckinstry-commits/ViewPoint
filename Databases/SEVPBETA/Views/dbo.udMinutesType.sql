SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create view [dbo].[udMinutesType] as select a.* From budMinutesType a
GO
GRANT SELECT ON  [dbo].[udMinutesType] TO [public]
GRANT INSERT ON  [dbo].[udMinutesType] TO [public]
GRANT DELETE ON  [dbo].[udMinutesType] TO [public]
GRANT UPDATE ON  [dbo].[udMinutesType] TO [public]
GO
