SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[PMPS] as select a.* From bPMPS a

GO
GRANT SELECT ON  [dbo].[PMPS] TO [public]
GRANT INSERT ON  [dbo].[PMPS] TO [public]
GRANT DELETE ON  [dbo].[PMPS] TO [public]
GRANT UPDATE ON  [dbo].[PMPS] TO [public]
GO
