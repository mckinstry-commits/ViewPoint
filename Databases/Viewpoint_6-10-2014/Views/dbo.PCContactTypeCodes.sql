SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[PCContactTypeCodes] as select a.* From vPCContactTypeCodes a

GO
GRANT SELECT ON  [dbo].[PCContactTypeCodes] TO [public]
GRANT INSERT ON  [dbo].[PCContactTypeCodes] TO [public]
GRANT DELETE ON  [dbo].[PCContactTypeCodes] TO [public]
GRANT UPDATE ON  [dbo].[PCContactTypeCodes] TO [public]
GRANT SELECT ON  [dbo].[PCContactTypeCodes] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PCContactTypeCodes] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PCContactTypeCodes] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PCContactTypeCodes] TO [Viewpoint]
GO
