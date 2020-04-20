CREATE TABLE [dbo].[vSMRateTemplate]
(
[SMRateTemplateID] [bigint] NOT NULL IDENTITY(1, 1),
[SMCo] [dbo].[bCompany] NOT NULL,
[RateTemplate] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Active] [dbo].[bYN] NOT NULL,
[LaborRate] [dbo].[bUnitCost] NOT NULL,
[EquipmentMarkup] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_vSMRateTemplate_EquipmentMarkup] DEFAULT ((0)),
[MaterialMarkupOrDiscount] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[MaterialBasis] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[MaterialPercent] [dbo].[bUnitCost] NOT NULL,
[SMRateOverrideID] [bigint] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMRateTemplate] ADD CONSTRAINT [PK_vSMRateTemplate] PRIMARY KEY CLUSTERED  ([SMRateTemplateID]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMRateTemplate] ADD CONSTRAINT [IX_vSMRateTemplate_SMCo_Template] UNIQUE NONCLUSTERED  ([SMCo], [RateTemplate]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[vSMRateTemplate] WITH NOCHECK ADD CONSTRAINT [FK_vSMRateTemplate_vSMCO] FOREIGN KEY ([SMCo]) REFERENCES [dbo].[vSMCO] ([SMCo])
GO
ALTER TABLE [dbo].[vSMRateTemplate] WITH NOCHECK ADD CONSTRAINT [FK_vSMRateTemplate_vSMRateOverride] FOREIGN KEY ([SMRateOverrideID]) REFERENCES [dbo].[vSMRateOverride] ([SMRateOverrideID])
GO
