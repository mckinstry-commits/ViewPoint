SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create view [dbo].[udProcVeh] as select a.* From budProcVeh a
GO
GRANT SELECT ON  [dbo].[udProcVeh] TO [public]
GRANT INSERT ON  [dbo].[udProcVeh] TO [public]
GRANT DELETE ON  [dbo].[udProcVeh] TO [public]
GRANT UPDATE ON  [dbo].[udProcVeh] TO [public]
GRANT SELECT ON  [dbo].[udProcVeh] TO [Viewpoint]
GRANT INSERT ON  [dbo].[udProcVeh] TO [Viewpoint]
GRANT DELETE ON  [dbo].[udProcVeh] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[udProcVeh] TO [Viewpoint]
GO
