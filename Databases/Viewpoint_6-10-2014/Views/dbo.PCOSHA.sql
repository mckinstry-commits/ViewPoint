SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[PCOSHA] as select a.* From vPCOSHA a

GO
GRANT SELECT ON  [dbo].[PCOSHA] TO [public]
GRANT INSERT ON  [dbo].[PCOSHA] TO [public]
GRANT DELETE ON  [dbo].[PCOSHA] TO [public]
GRANT UPDATE ON  [dbo].[PCOSHA] TO [public]
GRANT SELECT ON  [dbo].[PCOSHA] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PCOSHA] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PCOSHA] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PCOSHA] TO [Viewpoint]
GO