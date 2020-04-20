CREATE TABLE [dbo].[vSMCallTypeCategory]
(
[SMCallTypeCategoryID] [int] NOT NULL IDENTITY(1, 1),
[SMCo] [dbo].[bCompany] NOT NULL,
[CallTypeCategory] [varchar] (15) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bDesc] NULL,
[Color] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMCallTypeCategory] ADD CONSTRAINT [PK_vSMCallTypeCategory] PRIMARY KEY CLUSTERED  ([SMCallTypeCategoryID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMCallTypeCategory] ADD CONSTRAINT [IX_vSMCallTypeCategory_SMCo_CallTypeCategory] UNIQUE NONCLUSTERED  ([SMCo], [CallTypeCategory]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMCallTypeCategory] ADD CONSTRAINT [IX_vSMCallTypeCategory_SMCo_Color] UNIQUE NONCLUSTERED  ([SMCo], [Color]) ON [PRIMARY]
GO
