CREATE TABLE [dbo].[budxrefARCustomer]
(
[Company] [int] NOT NULL,
[OldCustomerID] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[CustGroup] [dbo].[bGroup] NULL,
[NewCustomerID] [dbo].[bCustomer] NULL,
[Name] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[ActiveYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF__budxrefAR__Activ__745D47B4] DEFAULT ('Y'),
[NewYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF__budxrefAR__NewYN__75516BED] DEFAULT ('Y'),
[Notes] [dbo].[bNotes] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[SMCustomer] [dbo].[bYN] NULL
) ON [PRIMARY]
GO
