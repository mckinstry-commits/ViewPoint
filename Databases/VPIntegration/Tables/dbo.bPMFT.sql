CREATE TABLE [dbo].[bPMFT]
(
[FirmType] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bDesc] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMFTd    Script Date: 8/28/99 9:37:52 AM ******/
CREATE trigger [dbo].[btPMFTd] on [dbo].[bPMFT] for DELETE as
/*--------------------------------------------------------------
 *  Delete trigger for PMFT
 *  Created By:  LM 12/18/97
 * Modified By:	GF 12/08/2006 - 6.x HQMA auditing
 *				JayR 03/21/2012 Change to use FK for validation.
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

---- HQMA inserts
insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPMFT','Firm Type: ' + isnull(d.FirmType,''), null, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from deleted d

RETURN 
   
  
 






GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMFTi    Script Date: 8/28/99 9:37:49 AM ******/
CREATE trigger [dbo].[btPMFTi] on [dbo].[bPMFT] for INSERT as
/*--------------------------------------------------------------
 * Insert trigger for PMFT
 * Created By:	GF 12/08/2006
 * Modified By:
 *
 *		
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

---- Audit inserts
insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPMFT', ' Key: ' + isnull(i.FirmType,''), null, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from inserted i


RETURN 


   
  
 








GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMFTu    Script Date: 8/28/99 9:37:53 AM ******/
CREATE trigger [dbo].[btPMFTu] on [dbo].[bPMFT] for UPDATE as
/*--------------------------------------------------------------
 * Update trigger for PMFT
 * Created By:	LM 12/18/97
 * Modified By:	GF 12/09/2006 - 6.x HQMA auditing
 *				JayR Change to use FK for validation
 *
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

---- check for changes to FirmType
if update(FirmType)
      begin
		RAISERROR('Cannot change FirmType - cannot update PMFT', 11, -1)
		ROLLBACK TRANSACTION
		RETURN 
      end


---- HQMA inserts
if update(Description)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMFT', 'Firm Type: ' + isnull(i.FirmType,''),
		null, 'C', 'Description',  d.Description, i.Description, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.FirmType=i.FirmType
	where isnull(d.Description,'') <> isnull(i.Description,'')



RETURN 
   
  
 





GO
CREATE UNIQUE CLUSTERED INDEX [biPMFT] ON [dbo].[bPMFT] ([FirmType]) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMFT] ([KeyID]) ON [PRIMARY]
GO
