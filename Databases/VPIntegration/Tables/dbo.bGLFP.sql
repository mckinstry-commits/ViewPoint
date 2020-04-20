CREATE TABLE [dbo].[bGLFP]
(
[GLCo] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[FiscalPd] [tinyint] NOT NULL,
[FiscalYr] [smallint] NOT NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bGLFP] ADD CONSTRAINT [PK_bGLFP] PRIMARY KEY CLUSTERED  ([GLCo], [Mth]) ON [PRIMARY]
GO
