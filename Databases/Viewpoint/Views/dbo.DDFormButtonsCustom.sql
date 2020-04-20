SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW dbo.DDFormButtonsCustom
AS
SELECT     a.*
FROM         dbo.vDDFormButtonsCustom a

GO
GRANT SELECT ON  [dbo].[DDFormButtonsCustom] TO [public]
GRANT INSERT ON  [dbo].[DDFormButtonsCustom] TO [public]
GRANT DELETE ON  [dbo].[DDFormButtonsCustom] TO [public]
GRANT UPDATE ON  [dbo].[DDFormButtonsCustom] TO [public]
GO
