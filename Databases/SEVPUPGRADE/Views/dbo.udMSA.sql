SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udMSA] as select a.* From budMSA a
GO
GRANT SELECT ON  [dbo].[udMSA] TO [public]
GRANT INSERT ON  [dbo].[udMSA] TO [public]
GRANT DELETE ON  [dbo].[udMSA] TO [public]
GRANT UPDATE ON  [dbo].[udMSA] TO [public]
GO
