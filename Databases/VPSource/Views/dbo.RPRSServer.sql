SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[RPRSServer] as select a.* From vRPRSServer a
GO
GRANT SELECT ON  [dbo].[RPRSServer] TO [public]
GRANT INSERT ON  [dbo].[RPRSServer] TO [public]
GRANT DELETE ON  [dbo].[RPRSServer] TO [public]
GRANT UPDATE ON  [dbo].[RPRSServer] TO [public]
GO
