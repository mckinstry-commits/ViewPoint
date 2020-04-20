SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HREI] as select a.* From bHREI a

GO
GRANT SELECT ON  [dbo].[HREI] TO [public]
GRANT INSERT ON  [dbo].[HREI] TO [public]
GRANT DELETE ON  [dbo].[HREI] TO [public]
GRANT UPDATE ON  [dbo].[HREI] TO [public]
GO
