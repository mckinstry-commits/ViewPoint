SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[frl_seg_ctrl] as select a.* From vfrl_seg_ctrl a

GO
GRANT SELECT ON  [dbo].[frl_seg_ctrl] TO [public]
GRANT INSERT ON  [dbo].[frl_seg_ctrl] TO [public]
GRANT DELETE ON  [dbo].[frl_seg_ctrl] TO [public]
GRANT UPDATE ON  [dbo].[frl_seg_ctrl] TO [public]
GRANT SELECT ON  [dbo].[frl_seg_ctrl] TO [Viewpoint]
GRANT INSERT ON  [dbo].[frl_seg_ctrl] TO [Viewpoint]
GRANT DELETE ON  [dbo].[frl_seg_ctrl] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[frl_seg_ctrl] TO [Viewpoint]
GO
