SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
	
CREATE View [dbo].[RFCommandUsage] as

select * from vRFCommandUsage


GO
GRANT SELECT ON  [dbo].[RFCommandUsage] TO [public]
GRANT INSERT ON  [dbo].[RFCommandUsage] TO [public]
GRANT DELETE ON  [dbo].[RFCommandUsage] TO [public]
GRANT UPDATE ON  [dbo].[RFCommandUsage] TO [public]
GO
