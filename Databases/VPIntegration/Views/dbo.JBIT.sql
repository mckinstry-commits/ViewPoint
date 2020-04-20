SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[JBIT] as select a.* From bJBIT a
GO
GRANT SELECT ON  [dbo].[JBIT] TO [public]
GRANT INSERT ON  [dbo].[JBIT] TO [public]
GRANT DELETE ON  [dbo].[JBIT] TO [public]
GRANT UPDATE ON  [dbo].[JBIT] TO [public]
GO
