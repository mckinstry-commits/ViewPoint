SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE    view [dbo].[DDTFc] as select a.* From vDDTFc a


GO
GRANT SELECT ON  [dbo].[DDTFc] TO [public]
GRANT INSERT ON  [dbo].[DDTFc] TO [public]
GRANT DELETE ON  [dbo].[DDTFc] TO [public]
GRANT UPDATE ON  [dbo].[DDTFc] TO [public]
GO
