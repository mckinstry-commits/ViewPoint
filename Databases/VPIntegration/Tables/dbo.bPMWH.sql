CREATE TABLE [dbo].[bPMWH]
(
[ImportId] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Template] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[PMCo] [dbo].[bCompany] NOT NULL,
[ImportDate] [datetime] NULL,
[ImportBy] [dbo].[bVPUserName] NULL,
[UploadDate] [datetime] NULL,
[UploadBy] [dbo].[bVPUserName] NULL,
[EstimateCode] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[Description] [dbo].[bItemDesc] NULL,
[JobPhone] [dbo].[bPhone] NULL,
[JobFax] [dbo].[bPhone] NULL,
[MailAddress] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[MailCity] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[MailState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[MailZip] [dbo].[bZip] NULL,
[MailAddress2] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[ShipAddress] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[ShipCity] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[ShipState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[ShipZip] [dbo].[bZip] NULL,
[ShipAddress2] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[SIRegion] [varchar] (6) COLLATE Latin1_General_BIN NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[MailCountry] [char] (2) COLLATE Latin1_General_BIN NULL,
[ShipCountry] [char] (2) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/****** Object:  Trigger dbo.btPMWHu    Script Date: 05/26/2006 ******/
CREATE trigger [dbo].[btPMWHu] on [dbo].[bPMWH] for UPDATE as

/*--------------------------------------------------------------
 *  Update trigger for PMWH
 *  Created By: GF 05/26/2006
 *	Modified By: JayR 03/29/2012 Remove usused variables
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

------ if the SIRegion has been updated, update PMWI.SIRegion
if update(SIRegion)
	begin
	update bPMWI set SIRegion = i.SIRegion
	from inserted i join bPMWI c on c.PMCo=i.PMCo and c.ImportId=i.ImportId
	end





GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMWH] ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPMWH] ON [dbo].[bPMWH] ([PMCo], [ImportId]) ON [PRIMARY]
GO
ALTER TABLE [dbo].[bPMWH] WITH NOCHECK ADD CONSTRAINT [FK_bPMWH_bPMCO] FOREIGN KEY ([PMCo]) REFERENCES [dbo].[bPMCO] ([PMCo])
GO
ALTER TABLE [dbo].[bPMWH] WITH NOCHECK ADD CONSTRAINT [FK_bPMWH_bPMUT] FOREIGN KEY ([Template]) REFERENCES [dbo].[bPMUT] ([Template])
GO
