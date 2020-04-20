SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE     view [dbo].[DDFR] as
select * from vDDFR

GO
GRANT SELECT ON  [dbo].[DDFR] TO [public]
GRANT INSERT ON  [dbo].[DDFR] TO [public]
GRANT DELETE ON  [dbo].[DDFR] TO [public]
GRANT UPDATE ON  [dbo].[DDFR] TO [public]
GO
