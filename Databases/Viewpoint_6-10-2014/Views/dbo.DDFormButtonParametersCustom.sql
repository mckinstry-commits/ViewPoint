SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[DDFormButtonParametersCustom] as
select * from vDDFormButtonParametersCustom

GO
GRANT SELECT ON  [dbo].[DDFormButtonParametersCustom] TO [public]
GRANT INSERT ON  [dbo].[DDFormButtonParametersCustom] TO [public]
GRANT DELETE ON  [dbo].[DDFormButtonParametersCustom] TO [public]
GRANT UPDATE ON  [dbo].[DDFormButtonParametersCustom] TO [public]
GRANT SELECT ON  [dbo].[DDFormButtonParametersCustom] TO [Viewpoint]
GRANT INSERT ON  [dbo].[DDFormButtonParametersCustom] TO [Viewpoint]
GRANT DELETE ON  [dbo].[DDFormButtonParametersCustom] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[DDFormButtonParametersCustom] TO [Viewpoint]
GO
