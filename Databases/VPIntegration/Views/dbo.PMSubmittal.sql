SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[PMSubmittal] as select a.* From vPMSubmittal a

GO
GRANT SELECT ON  [dbo].[PMSubmittal] TO [public]
GRANT INSERT ON  [dbo].[PMSubmittal] TO [public]
GRANT DELETE ON  [dbo].[PMSubmittal] TO [public]
GRANT UPDATE ON  [dbo].[PMSubmittal] TO [public]
GO
