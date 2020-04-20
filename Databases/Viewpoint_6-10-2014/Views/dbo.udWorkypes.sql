SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[udWorkypes] as select a.* From budWorkypes a
GO
GRANT SELECT ON  [dbo].[udWorkypes] TO [public]
GRANT INSERT ON  [dbo].[udWorkypes] TO [public]
GRANT DELETE ON  [dbo].[udWorkypes] TO [public]
GRANT UPDATE ON  [dbo].[udWorkypes] TO [public]
GO
