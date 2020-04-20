SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
	
CREATE View [dbo].[RFEpisodeUsage] as

select * from vRFEpisodeUsage


GO
GRANT SELECT ON  [dbo].[RFEpisodeUsage] TO [public]
GRANT INSERT ON  [dbo].[RFEpisodeUsage] TO [public]
GRANT DELETE ON  [dbo].[RFEpisodeUsage] TO [public]
GRANT UPDATE ON  [dbo].[RFEpisodeUsage] TO [public]
GO
