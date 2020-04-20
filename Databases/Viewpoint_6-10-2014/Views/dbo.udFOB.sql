SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create view [dbo].[udFOB] as select a.* From budFOB a
GO
GRANT SELECT ON  [dbo].[udFOB] TO [public]
GRANT INSERT ON  [dbo].[udFOB] TO [public]
GRANT DELETE ON  [dbo].[udFOB] TO [public]
GRANT UPDATE ON  [dbo].[udFOB] TO [public]
GO
