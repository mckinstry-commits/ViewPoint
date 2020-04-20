SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HQCC] as select a.* From bHQCC a

GO
GRANT SELECT ON  [dbo].[HQCC] TO [public]
GRANT INSERT ON  [dbo].[HQCC] TO [public]
GRANT DELETE ON  [dbo].[HQCC] TO [public]
GRANT UPDATE ON  [dbo].[HQCC] TO [public]
GO
