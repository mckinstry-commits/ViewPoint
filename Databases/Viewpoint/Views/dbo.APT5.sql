SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[APT5] as select a.* From bAPT5 a

GO
GRANT SELECT ON  [dbo].[APT5] TO [public]
GRANT INSERT ON  [dbo].[APT5] TO [public]
GRANT DELETE ON  [dbo].[APT5] TO [public]
GRANT UPDATE ON  [dbo].[APT5] TO [public]
GO
