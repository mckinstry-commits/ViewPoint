SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE    view [dbo].[DDTDc] as select a.* From vDDTDc a


GO
GRANT SELECT ON  [dbo].[DDTDc] TO [public]
GRANT INSERT ON  [dbo].[DDTDc] TO [public]
GRANT DELETE ON  [dbo].[DDTDc] TO [public]
GRANT UPDATE ON  [dbo].[DDTDc] TO [public]
GO
