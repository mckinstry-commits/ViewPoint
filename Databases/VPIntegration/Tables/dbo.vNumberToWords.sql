CREATE TABLE [dbo].[vNumberToWords]
(
[NumValue] [bigint] NOT NULL,
[NumDescription] [varchar] (32) COLLATE Latin1_General_BIN NOT NULL,
[PrefixNum] [bit] NOT NULL CONSTRAINT [DF__vNumberTo__Prefi__31C01FB9] DEFAULT ((0)),
[DispOnly] [bit] NOT NULL CONSTRAINT [DF__vNumberTo__DispO__32B443F2] DEFAULT ((0))
) ON [PRIMARY]
GO
