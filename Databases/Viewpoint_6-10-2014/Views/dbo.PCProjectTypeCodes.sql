SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[PCProjectTypeCodes] as select a.* From vPCProjectTypeCodes a

GO
GRANT SELECT ON  [dbo].[PCProjectTypeCodes] TO [public]
GRANT INSERT ON  [dbo].[PCProjectTypeCodes] TO [public]
GRANT DELETE ON  [dbo].[PCProjectTypeCodes] TO [public]
GRANT UPDATE ON  [dbo].[PCProjectTypeCodes] TO [public]
GRANT SELECT ON  [dbo].[PCProjectTypeCodes] TO [Viewpoint]
GRANT INSERT ON  [dbo].[PCProjectTypeCodes] TO [Viewpoint]
GRANT DELETE ON  [dbo].[PCProjectTypeCodes] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[PCProjectTypeCodes] TO [Viewpoint]
GO
