SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HRTC] as select a.* From bHRTC a

GO
GRANT SELECT ON  [dbo].[HRTC] TO [public]
GRANT INSERT ON  [dbo].[HRTC] TO [public]
GRANT DELETE ON  [dbo].[HRTC] TO [public]
GRANT UPDATE ON  [dbo].[HRTC] TO [public]
GO
