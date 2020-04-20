SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE    VIEW dbo.DDCIc
AS
SELECT     *
FROM         dbo.vDDCIc






GO
GRANT SELECT ON  [dbo].[DDCIc] TO [public]
GRANT INSERT ON  [dbo].[DDCIc] TO [public]
GRANT DELETE ON  [dbo].[DDCIc] TO [public]
GRANT UPDATE ON  [dbo].[DDCIc] TO [public]
GO
