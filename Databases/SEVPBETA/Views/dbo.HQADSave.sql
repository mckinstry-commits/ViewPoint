SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[HQADSave] as select a.* From bHQADSave a
GO
GRANT SELECT ON  [dbo].[HQADSave] TO [public]
GRANT INSERT ON  [dbo].[HQADSave] TO [public]
GRANT DELETE ON  [dbo].[HQADSave] TO [public]
GRANT UPDATE ON  [dbo].[HQADSave] TO [public]
GO
