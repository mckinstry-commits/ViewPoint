CREATE TABLE [dbo].[vDDCS]
(
[ColorSchemeID] [int] NOT NULL,
[Description] [dbo].[bDesc] NULL,
[SmartCursorColor] [int] NULL,
[ReqFieldColor] [int] NULL,
[AccentColor1] [int] NULL,
[AccentColor2] [int] NULL,
[UseColorGrad] [dbo].[bYN] NULL,
[FormColor1] [int] NULL,
[FormColor2] [int] NULL,
[GradDirection] [tinyint] NULL,
[LabelBackgroundColor] [int] NULL,
[LabelTextColor] [int] NULL,
[LabelBorderStyle] [tinyint] NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vDDCS] WITH NOCHECK ADD CONSTRAINT [CK_vDDCS_UseColorGrad] CHECK (([UseColorGrad]='Y' OR [UseColorGrad]='N' OR [UseColorGrad] IS NULL))
GO
CREATE UNIQUE CLUSTERED INDEX [viDDCS] ON [dbo].[vDDCS] ([ColorSchemeID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
