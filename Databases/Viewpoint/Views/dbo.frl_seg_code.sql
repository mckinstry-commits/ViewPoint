SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[frl_seg_code] as select a.* From vfrl_seg_code a

GO
GRANT SELECT ON  [dbo].[frl_seg_code] TO [public]
GRANT INSERT ON  [dbo].[frl_seg_code] TO [public]
GRANT DELETE ON  [dbo].[frl_seg_code] TO [public]
GRANT UPDATE ON  [dbo].[frl_seg_code] TO [public]
GO
