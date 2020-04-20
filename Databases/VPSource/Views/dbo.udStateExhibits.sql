SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udStateExhibits] as select a.* From budStateExhibits a
GO
GRANT SELECT ON  [dbo].[udStateExhibits] TO [public]
GRANT INSERT ON  [dbo].[udStateExhibits] TO [public]
GRANT DELETE ON  [dbo].[udStateExhibits] TO [public]
GRANT UPDATE ON  [dbo].[udStateExhibits] TO [public]
GO
