SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE   view [dbo].[RPFRc] as select a.* From vRPFRc  a







GO
GRANT SELECT ON  [dbo].[RPFRc] TO [public]
GRANT INSERT ON  [dbo].[RPFRc] TO [public]
GRANT DELETE ON  [dbo].[RPFRc] TO [public]
GRANT UPDATE ON  [dbo].[RPFRc] TO [public]
GO
