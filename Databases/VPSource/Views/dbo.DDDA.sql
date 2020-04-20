SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE  view [dbo].[DDDA] as select a.* From vDDDA a





GO
GRANT SELECT ON  [dbo].[DDDA] TO [public]
GRANT INSERT ON  [dbo].[DDDA] TO [public]
GRANT DELETE ON  [dbo].[DDDA] TO [public]
GRANT UPDATE ON  [dbo].[DDDA] TO [public]
GO
