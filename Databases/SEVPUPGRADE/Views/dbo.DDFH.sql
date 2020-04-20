SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  view [dbo].[DDFH] as
select a.* From vDDFH a


GO
GRANT SELECT ON  [dbo].[DDFH] TO [public]
GRANT INSERT ON  [dbo].[DDFH] TO [public]
GRANT DELETE ON  [dbo].[DDFH] TO [public]
GRANT UPDATE ON  [dbo].[DDFH] TO [public]
GO
