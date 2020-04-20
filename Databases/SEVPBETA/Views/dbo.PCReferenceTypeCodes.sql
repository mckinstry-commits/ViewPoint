SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[PCReferenceTypeCodes] as select a.* From vPCReferenceTypeCodes a

GO
GRANT SELECT ON  [dbo].[PCReferenceTypeCodes] TO [public]
GRANT INSERT ON  [dbo].[PCReferenceTypeCodes] TO [public]
GRANT DELETE ON  [dbo].[PCReferenceTypeCodes] TO [public]
GRANT UPDATE ON  [dbo].[PCReferenceTypeCodes] TO [public]
GO
