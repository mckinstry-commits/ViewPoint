SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[frl_seg_tree] as select a.* From vfrl_seg_tree a

GO
GRANT SELECT ON  [dbo].[frl_seg_tree] TO [public]
GRANT INSERT ON  [dbo].[frl_seg_tree] TO [public]
GRANT DELETE ON  [dbo].[frl_seg_tree] TO [public]
GRANT UPDATE ON  [dbo].[frl_seg_tree] TO [public]
GO
