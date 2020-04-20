SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRArrears] as select a.* From vPRArrears a
GO
GRANT SELECT ON  [dbo].[PRArrears] TO [public]
GRANT INSERT ON  [dbo].[PRArrears] TO [public]
GRANT DELETE ON  [dbo].[PRArrears] TO [public]
GRANT UPDATE ON  [dbo].[PRArrears] TO [public]
GRANT SELECT ON  [dbo].[PRArrears] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRArrears] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRArrears] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRArrears] TO [Viewpoint]
GO
