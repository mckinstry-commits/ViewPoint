SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udSubStateExhibits] as select a.* From budSubStateExhibits a
GO
GRANT SELECT ON  [dbo].[udSubStateExhibits] TO [public]
GRANT INSERT ON  [dbo].[udSubStateExhibits] TO [public]
GRANT DELETE ON  [dbo].[udSubStateExhibits] TO [public]
GRANT UPDATE ON  [dbo].[udSubStateExhibits] TO [public]
GRANT SELECT ON  [dbo].[udSubStateExhibits] TO [Viewpoint]
GRANT INSERT ON  [dbo].[udSubStateExhibits] TO [Viewpoint]
GRANT DELETE ON  [dbo].[udSubStateExhibits] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[udSubStateExhibits] TO [Viewpoint]
GO
