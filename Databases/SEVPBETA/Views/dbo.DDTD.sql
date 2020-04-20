SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE    view [dbo].[DDTD] as select a.* From vDDTD a

GO
GRANT SELECT ON  [dbo].[DDTD] TO [public]
GRANT INSERT ON  [dbo].[DDTD] TO [public]
GRANT DELETE ON  [dbo].[DDTD] TO [public]
GRANT UPDATE ON  [dbo].[DDTD] TO [public]
GO
