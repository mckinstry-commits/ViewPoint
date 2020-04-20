SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HQWT] as select a.* From bHQWT a

GO
GRANT SELECT ON  [dbo].[HQWT] TO [public]
GRANT INSERT ON  [dbo].[HQWT] TO [public]
GRANT DELETE ON  [dbo].[HQWT] TO [public]
GRANT UPDATE ON  [dbo].[HQWT] TO [public]
GO
