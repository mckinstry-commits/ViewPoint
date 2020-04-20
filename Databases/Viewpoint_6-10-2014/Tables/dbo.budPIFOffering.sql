CREATE TABLE [dbo].[budPIFOffering]
(
[Co] [dbo].[bCompany] NOT NULL,
[Amount] [dbo].[bDollar] NULL,
[Offering] [dbo].[bDesc] NOT NULL,
[ProjHours] [dbo].[bHrs] NULL,
[ProjStart] [dbo].[bDate] NULL,
[ReqNum] [int] NOT NULL,
[UserName] [dbo].[bVPUserName] NOT NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[SelfPerfYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_udPIFOffering_SelfPerfYN] DEFAULT ('N'),
[SubcontractYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_udPIFOffering_SubcontractYN] DEFAULT ('N')
) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biudPIFOffering] ON [dbo].[budPIFOffering] ([Co], [UserName], [ReqNum], [Offering]) ON [PRIMARY]
GO
