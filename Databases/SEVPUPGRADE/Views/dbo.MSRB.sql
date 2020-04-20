SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[MSRB] as select a.* From bMSRB a

GO
GRANT SELECT ON  [dbo].[MSRB] TO [public]
GRANT INSERT ON  [dbo].[MSRB] TO [public]
GRANT DELETE ON  [dbo].[MSRB] TO [public]
GRANT UPDATE ON  [dbo].[MSRB] TO [public]
GO
