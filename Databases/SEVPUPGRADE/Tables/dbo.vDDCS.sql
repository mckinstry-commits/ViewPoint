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
CREATE UNIQUE CLUSTERED INDEX [viDDCS] ON [dbo].[vDDCS] ([ColorSchemeID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[vDDCS].[UseColorGrad]'
GO
