SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[EMAH] as select a.* From bEMAH a
GO
GRANT SELECT ON  [dbo].[EMAH] TO [public]
GRANT INSERT ON  [dbo].[EMAH] TO [public]
GRANT DELETE ON  [dbo].[EMAH] TO [public]
GRANT UPDATE ON  [dbo].[EMAH] TO [public]
GRANT SELECT ON  [dbo].[EMAH] TO [Viewpoint]
GRANT INSERT ON  [dbo].[EMAH] TO [Viewpoint]
GRANT DELETE ON  [dbo].[EMAH] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[EMAH] TO [Viewpoint]
GO
