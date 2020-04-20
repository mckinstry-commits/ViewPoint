SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE view [dbo].[PMDocumentMapping] as select a.* From vPMDocumentMapping a

GO
GRANT SELECT ON  [dbo].[PMDocumentMapping] TO [public]
GRANT INSERT ON  [dbo].[PMDocumentMapping] TO [public]
GRANT DELETE ON  [dbo].[PMDocumentMapping] TO [public]
GRANT UPDATE ON  [dbo].[PMDocumentMapping] TO [public]
GO
