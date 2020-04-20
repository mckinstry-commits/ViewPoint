SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  view [dbo].[DDFIc] as
select a.* From vDDFIc a

GO
GRANT SELECT ON  [dbo].[DDFIc] TO [public]
GRANT INSERT ON  [dbo].[DDFIc] TO [public]
GRANT DELETE ON  [dbo].[DDFIc] TO [public]
GRANT UPDATE ON  [dbo].[DDFIc] TO [public]
GRANT SELECT ON  [dbo].[DDFIc] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DDFIc] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DDFIc] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DDFIc] TO [Viewpoint]
GO
