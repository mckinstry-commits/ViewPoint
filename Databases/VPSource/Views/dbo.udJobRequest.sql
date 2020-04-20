SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udJobRequest] as select a.* From budJobRequest a
GO
GRANT SELECT ON  [dbo].[udJobRequest] TO [public]
GRANT INSERT ON  [dbo].[udJobRequest] TO [public]
GRANT DELETE ON  [dbo].[udJobRequest] TO [public]
GRANT UPDATE ON  [dbo].[udJobRequest] TO [public]
GO
