SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[PCProjectTypes] as select a.* From vPCProjectTypes a

GO
GRANT SELECT ON  [dbo].[PCProjectTypes] TO [public]
GRANT INSERT ON  [dbo].[PCProjectTypes] TO [public]
GRANT DELETE ON  [dbo].[PCProjectTypes] TO [public]
GRANT UPDATE ON  [dbo].[PCProjectTypes] TO [public]
GO
