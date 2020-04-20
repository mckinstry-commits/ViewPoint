SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE  view [dbo].[DDGridGroupingColumn] as
select a.* From vDDGridGroupingColumn a





GO
GRANT SELECT ON  [dbo].[DDGridGroupingColumn] TO [public]
GRANT INSERT ON  [dbo].[DDGridGroupingColumn] TO [public]
GRANT DELETE ON  [dbo].[DDGridGroupingColumn] TO [public]
GRANT UPDATE ON  [dbo].[DDGridGroupingColumn] TO [public]
GO
