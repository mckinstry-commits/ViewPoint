SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE   view [dbo].[PMEmailSignature] as select * from vPMEmailSignature

GO
GRANT SELECT ON  [dbo].[PMEmailSignature] TO [public]
GRANT INSERT ON  [dbo].[PMEmailSignature] TO [public]
GRANT DELETE ON  [dbo].[PMEmailSignature] TO [public]
GRANT UPDATE ON  [dbo].[PMEmailSignature] TO [public]
GO
