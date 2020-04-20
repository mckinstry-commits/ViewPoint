SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[APTT] as select a.* From bAPTT a

GO
GRANT SELECT ON  [dbo].[APTT] TO [public]
GRANT INSERT ON  [dbo].[APTT] TO [public]
GRANT DELETE ON  [dbo].[APTT] TO [public]
GRANT UPDATE ON  [dbo].[APTT] TO [public]
GO
