SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PRTC] as select a.* From bPRTC a
GO
GRANT SELECT ON  [dbo].[PRTC] TO [public]
GRANT INSERT ON  [dbo].[PRTC] TO [public]
GRANT DELETE ON  [dbo].[PRTC] TO [public]
GRANT UPDATE ON  [dbo].[PRTC] TO [public]
GRANT SELECT ON  [dbo].[PRTC] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PRTC] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PRTC] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PRTC] TO [Viewpoint]
GO
