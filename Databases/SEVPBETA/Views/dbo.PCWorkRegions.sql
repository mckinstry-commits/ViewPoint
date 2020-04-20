SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE view [dbo].[PCWorkRegions] as select a.* From vPCWorkRegions a


GO
GRANT SELECT ON  [dbo].[PCWorkRegions] TO [public]
GRANT INSERT ON  [dbo].[PCWorkRegions] TO [public]
GRANT DELETE ON  [dbo].[PCWorkRegions] TO [public]
GRANT UPDATE ON  [dbo].[PCWorkRegions] TO [public]
GO
