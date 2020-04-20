SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[IMKV] as select a.* From bIMKV a

GO
GRANT SELECT ON  [dbo].[IMKV] TO [public]
GRANT INSERT ON  [dbo].[IMKV] TO [public]
GRANT DELETE ON  [dbo].[IMKV] TO [public]
GRANT UPDATE ON  [dbo].[IMKV] TO [public]
GO
