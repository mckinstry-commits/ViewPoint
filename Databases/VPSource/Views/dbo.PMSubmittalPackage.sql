SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[PMSubmittalPackage] as select a.* From vPMSubmittalPackage a

GO
GRANT SELECT ON  [dbo].[PMSubmittalPackage] TO [public]
GRANT INSERT ON  [dbo].[PMSubmittalPackage] TO [public]
GRANT DELETE ON  [dbo].[PMSubmittalPackage] TO [public]
GRANT UPDATE ON  [dbo].[PMSubmittalPackage] TO [public]
GO
