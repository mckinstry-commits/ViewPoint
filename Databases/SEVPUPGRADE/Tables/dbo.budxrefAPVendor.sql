CREATE TABLE [dbo].[budxrefAPVendor]
(
[Company] [int] NOT NULL,
[OldVendorID] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[CGCVendorType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[VendorGroup] [dbo].[bGroup] NULL,
[NewVendorID] [dbo].[bVendor] NULL,
[Name] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[ActiveYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF__budxrefAP__Activ__7739B45F] DEFAULT ('Y'),
[Notes] [dbo].[bNotes] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY]
GO
