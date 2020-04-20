USE [MCK_INTEGRATION]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

SET ANSI_PADDING ON
GO

CREATE TABLE [dbo].[APCompanyMove](
	[APCompanyMoveID] [int] IDENTITY(1,1) NOT NULL,
	[LogFileName] [varchar] (200) NULL,
	[HeaderSuccess] [bit] NULL,
	[AttachSuccess] [bit] NULL,
	[AttachCopySuccess] [bit] NULL,
	[Mth] [smalldatetime] NULL,
	[Vendor] [int] NULL,
	[APRef]  [varchar] (15) NULL,
	[InvTotal] [numeric] (12, 2) NULL,
	[Co] [tinyint] NULL,
	[UISeq] [smallint] NULL,
	[UniqueAttchID] [uniqueidentifier] NULL,
	[KeyID] [bigint] NULL,
	[DestCo] [tinyint] NULL,
	[DestUISeq] [smallint] NULL,
	[DestUniqueAttchID] [uniqueidentifier] NULL,
	[DestKeyID] [bigint] NULL,
	[RLBProcessNotesID] [int] NULL,
    [Created] [datetime] NULL,
	[Modified] [datetime] NULL,

 CONSTRAINT [PK_APCompanyMove] PRIMARY KEY CLUSTERED 
(
	[APCompanyMoveID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY]

GO

SET ANSI_PADDING OFF
GO

ALTER TABLE [dbo].[APCompanyMove] ADD  CONSTRAINT [DF_APCompanyMove_LogFileName]  DEFAULT (NULL) FOR [LogFileName]
GO

ALTER TABLE [dbo].[APCompanyMove] ADD  CONSTRAINT [DF_APCompanyMove_HeaderSuccess]  DEFAULT (NULL) FOR [HeaderSuccess]
GO

ALTER TABLE [dbo].[APCompanyMove] ADD  CONSTRAINT [DF_APCompanyMove_AttachSuccess]  DEFAULT (NULL) FOR [AttachSuccess]
GO

ALTER TABLE [dbo].[APCompanyMove] ADD  CONSTRAINT [DF_APCompanyMove_AttachCopySuccess]  DEFAULT (NULL) FOR [AttachCopySuccess]
GO

ALTER TABLE [dbo].[APCompanyMove] ADD  CONSTRAINT [DF_APCompanyMove_Mth]  DEFAULT (NULL) FOR [Mth]
GO

ALTER TABLE [dbo].[APCompanyMove] ADD  CONSTRAINT [DF_APCompanyMove_Vendor]  DEFAULT (NULL) FOR [Vendor]
GO

ALTER TABLE [dbo].[APCompanyMove] ADD  CONSTRAINT [DF_APCompanyMove_APRef]  DEFAULT (NULL) FOR [APRef]
GO

ALTER TABLE [dbo].[APCompanyMove] ADD  CONSTRAINT [DF_APCompanyMove_InvTotal]  DEFAULT (NULL) FOR [InvTotal]
GO

ALTER TABLE [dbo].[APCompanyMove] ADD  CONSTRAINT [DF_APCompanyMove_Co]  DEFAULT (NULL) FOR [Co]
GO

ALTER TABLE [dbo].[APCompanyMove] ADD  CONSTRAINT [DF_APCompanyMove_UISeq]  DEFAULT (NULL) FOR [UISeq]
GO

ALTER TABLE [dbo].[APCompanyMove] ADD  CONSTRAINT [DF_APCompanyMove_UniqueAttchID]  DEFAULT (NULL) FOR [UniqueAttchID]
GO

ALTER TABLE [dbo].[APCompanyMove] ADD  CONSTRAINT [DF_APCompanyMove_KeyID]  DEFAULT (NULL) FOR [KeyID]
GO

ALTER TABLE [dbo].[APCompanyMove] ADD  CONSTRAINT [DF_APCompanyMove_DestCo]  DEFAULT (NULL) FOR [DestCo]
GO

ALTER TABLE [dbo].[APCompanyMove] ADD  CONSTRAINT [DF_APCompanyMove_DestUISeq]  DEFAULT (NULL) FOR [DestUISeq]
GO

ALTER TABLE [dbo].[APCompanyMove] ADD  CONSTRAINT [DF_APCompanyMove_DestUniqueAttchID]  DEFAULT (NULL) FOR [DestUniqueAttchID]
GO

ALTER TABLE [dbo].[APCompanyMove] ADD  CONSTRAINT [DF_APCompanyMove_DestKeyID]  DEFAULT (NULL) FOR [DestKeyID]
GO

ALTER TABLE [dbo].[APCompanyMove] ADD  CONSTRAINT [DF_APCompanyMove_RLBProcessNotesID]  DEFAULT (NULL) FOR [RLBProcessNotesID]
GO

ALTER TABLE [dbo].[APCompanyMove] ADD  CONSTRAINT [DF_APCompanyMove_Created]  DEFAULT (getdate()) FOR [Created]
GO

ALTER TABLE [dbo].[APCompanyMove] ADD  CONSTRAINT [DF_APCompanyMove_Modified]  DEFAULT (getdate()) FOR [Modified]
GO

ALTER TABLE [dbo].[APCompanyMove]  WITH CHECK ADD CONSTRAINT [FK_APCompanyMove_RLBProcessNotesID] FOREIGN KEY([RLBProcessNotesID])
REFERENCES [dbo].[RLBProcessNotes] ([RLBProcessNotesID])
GO
ALTER TABLE [dbo].[APCompanyMove] CHECK CONSTRAINT [FK_APCompanyMove_RLBProcessNotesID]
GO

