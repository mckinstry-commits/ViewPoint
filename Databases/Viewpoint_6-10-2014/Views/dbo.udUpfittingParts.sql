SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create view [dbo].[udUpfittingParts] as select a.* From budUpfittingParts a
GO
GRANT SELECT ON  [dbo].[udUpfittingParts] TO [public]
GRANT INSERT ON  [dbo].[udUpfittingParts] TO [public]
GRANT DELETE ON  [dbo].[udUpfittingParts] TO [public]
GRANT UPDATE ON  [dbo].[udUpfittingParts] TO [public]
GO
