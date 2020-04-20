CREATE TABLE [dbo].[bPMDT]
(
[DocType] [dbo].[bDocType] NOT NULL,
[DocCategory] [varchar] (10) COLLATE Latin1_General_BIN NOT NULL,
[Description] [dbo].[bDesc] NULL,
[PCODate1] [dbo].[bDesc] NULL,
[ShowPCODate1] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMDT_ShowPCODate1] DEFAULT ('N'),
[PCODate2] [dbo].[bDesc] NULL,
[ShowPCODate2] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMDT_ShowPCODate2] DEFAULT ('N'),
[PCODate3] [dbo].[bDesc] NULL,
[ShowPCODate3] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMDT_ShowPCODate3] DEFAULT ('N'),
[PCOItemDate1] [dbo].[bDesc] NULL,
[ShowPCOItemDate1] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMDT_ShowPCOItemDate1] DEFAULT ('N'),
[PCOItemDate2] [dbo].[bDesc] NULL,
[ShowPCOItemDate2] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMDT_ShowPCOItemDate2] DEFAULT ('N'),
[PCOItemDate3] [dbo].[bDesc] NULL,
[ShowPCOItemDate3] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMDT_ShowPCOItemDate3] DEFAULT ('N'),
[IncludeInProj] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMDT_IncludeInProj] DEFAULT ('N'),
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[Active] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMDT_Active] DEFAULT ('Y'),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[IntExtDefault] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMDT_IntExtDefault] DEFAULT ('N'),
[InitAddons] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMDT_InitAddons] DEFAULT ('Y'),
[BudgetType] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMDT_BudgetType] DEFAULT ('N'),
[SubType] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMDT_SubType] DEFAULT ('N'),
[POType] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMDT_POType] DEFAULT ('N'),
[ContractType] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMDT_ContractType] DEFAULT ('N'),
[PriceMethod] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bPMDT_UnitPriceMethod] DEFAULT ('L'),
[udCIPrimDocType] [varchar] (50) COLLATE Latin1_General_BIN NULL,
[SystemUse] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bPMDT_SystemUse] DEFAULT ('N')
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
ALTER TABLE [dbo].[bPMDT] ADD
CONSTRAINT [CK_bPMDT_Active] CHECK (([Active]='Y' OR [Active]='N'))
ALTER TABLE [dbo].[bPMDT] ADD
CONSTRAINT [CK_bPMDT_DocCategory] CHECK (([DocCategory]='SBMTLPCKG' OR [DocCategory]='SBMTL' OR [DocCategory]='DAILYLOG' OR [DocCategory]='ACO' OR [DocCategory]='PURCHASE' OR [DocCategory]='PO' OR [DocCategory]='PUNCH' OR [DocCategory]='CCO' OR [DocCategory]='POCO' OR [DocCategory]='PURCHASECO' OR [DocCategory]='COR' OR [DocCategory]='SUBCO' OR [DocCategory]='ISSUE' OR [DocCategory]='TEST' OR [DocCategory]='INSPECT' OR [DocCategory]='DRAWING' OR [DocCategory]='OTHER' OR [DocCategory]='MTG' OR [DocCategory]='SUBMIT' OR [DocCategory]='RFI' OR [DocCategory]='REQQUOTE' OR [DocCategory]='PCO' OR [DocCategory]='SUB' OR [DocCategory]='TRANSMIT'))
ALTER TABLE [dbo].[bPMDT] ADD
CONSTRAINT [CK_bPMDT_IncludeInProj] CHECK (([IncludeInProj]='Y' OR [IncludeInProj]='N'))
ALTER TABLE [dbo].[bPMDT] ADD
CONSTRAINT [CK_bPMDT_ShowPCODate1] CHECK (([ShowPCODate1]='Y' OR [ShowPCODate1]='N'))
ALTER TABLE [dbo].[bPMDT] ADD
CONSTRAINT [CK_bPMDT_ShowPCODate2] CHECK (([ShowPCODate2]='Y' OR [ShowPCODate2]='N'))
ALTER TABLE [dbo].[bPMDT] ADD
CONSTRAINT [CK_bPMDT_ShowPCODate3] CHECK (([ShowPCODate3]='Y' OR [ShowPCODate3]='N'))
ALTER TABLE [dbo].[bPMDT] ADD
CONSTRAINT [CK_bPMDT_ShowPCOItemDate1] CHECK (([ShowPCOItemDate1]='Y' OR [ShowPCOItemDate1]='N'))
ALTER TABLE [dbo].[bPMDT] ADD
CONSTRAINT [CK_bPMDT_ShowPCOItemDate2] CHECK (([ShowPCOItemDate2]='Y' OR [ShowPCOItemDate2]='N'))
ALTER TABLE [dbo].[bPMDT] ADD
CONSTRAINT [CK_bPMDT_ShowPCOItemDate3] CHECK (([ShowPCOItemDate3]='Y' OR [ShowPCOItemDate3]='N'))
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



/****** Object:  Trigger dbo.btPMDTd    Script Date: 8/28/99 9:37:51 AM ******/
CREATE  trigger [dbo].[btPMDTd] on [dbo].[bPMDT] for DELETE as
/*--------------------------------------------------------------
 *  Delete trigger for PMDT
 *  Created By:		LM 12/18/97
 *  Modified By:	GF 04/17/2002 - Added checks for PMDG, PMIL, PMTL
 *					JayR 03/21/2012 TK-00000 Change to using FK for constraints	
 *					GP 12/03/2012 - TK-19818 Make sure user cannot delete default submittal package doctype		
 *					SCOTTP 05/06/2013 - TFS-47183  Add support for Transmit DocType column
 *					AJW 05/10/13 - TFS 13608 delete any default templates for the project
 *					SCOTTP 06/24/2013 - TFS-53584 Don't allow delete if SystemUse = 'Y'
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

DECLARE @errmsg VARCHAR(255)

IF EXISTS(SELECT 1 FROM DELETED WHERE DocType IN ('SBMTLPCKG','SUB','PURCHASE',
	'ACO','SUBCO','POCO','CCO','COR','DAILYLOG','REQQUOTE','PUNCH','TRANSMIT')
	)
BEGIN
	select @errmsg = 'Cannot delete default document types used for Create and Send'
	goto error
END

IF EXISTS(SELECT 1 FROM DELETED WHERE SystemUse = 'Y')
BEGIN
	select @errmsg = 'Cannot delete document types that are marked for System Use'
	goto error
END

-- delete any reference to this doctype in vPMProjectDefaultDocumentDistribution
delete vPMProjectDefaultDocumentDistribution
from vPMProjectDefaultDocumentDistribution p
join DELETED d on p.DocCategory=d.DocCategory and p.DocType=d.DocType
where p.DocType is not null

--delete any reference to this doctype in PMProjectMasterTemplates
delete vPMProjectMasterTemplates
from vPMProjectMasterTemplates t
join DELETED d on t.DocType = d.DocType and t.DocCategory = d.DocCategory
where t.DocType is not null

---- HQMA inserts
insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPMDT','Doc Type: ' + isnull(d.DocType,''), null, 'D', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from deleted d

RETURN


error:
	select @errmsg = isnull(@errmsg, '') + ' - cannot delete from PMDT'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction
   
  
 






GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btPMDTi    Script Date: 8/28/99 9:37:51 AM ******/
    CREATE   trigger [dbo].[btPMDTi] on [dbo].[bPMDT] for INSERT as
/*--------------------------------------------------------------
 *  Insert trigger for PMDT
 *  Created By: LM 12/18/97
 *  Modified By: GF 04/03/2002 - added DRAWING, INSPECT, and TEST to document categories
 *					GF 08/10/2010 - issue #
 *					GP 02/15/2011 - added SUBCO to check
 *					GF 02/21/2011 - check internal/external flag using impact types B-02849
 *					GP 03/19/2011 - added COR to doc category check
 *					DAN SO 03/31/2011 - added POCO to doc category check
 *					DAN SO 01/12/2012 - TK-11052 - added PO to doc category check
 *					JayR 03/21/2012 TK-00000 Change to use table constraint for data validation
 *
 *--------------------------------------------------------------*/

if @@rowcount = 0 return
set nocount on

---- IntExtDefault must be 'E' if Contract Type = 'Y'
UPDATE dbo.bPMDT SET IntExtDefault = 'E'
FROM INSERTED i WHERE i.ContractType = 'Y' AND i.IntExtDefault = 'I'

---- Audit inserts
insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
select 'bPMDT', ' Key: ' + isnull(i.DocType,''), null, 'A', NULL, NULL, NULL, getdate(), SUSER_SNAME()
from inserted i

RETURN 
    
   
   
   
   
  
 




GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/****** Object:  Trigger dbo.btPMDTu    Script Date: 8/28/99 9:37:51 AM ******/
CREATE trigger [dbo].[btPMDTu] on [dbo].[bPMDT] for UPDATE as
/*--------------------------------------------------------------
 *  Update trigger for PMDT
 *  Created By:   LM 2/11/98
 *  Modified By:  GF 04/03/2002 - added DRAWING to document categories
 *				  GF 03/05/2009 - issue #132108
 *					GF 08/10/2010 - issue #
 *					GP 02/15/2011 - added SUBCO to check
 *					GF 02/21/2011 - new columns V1: B-02849
 *					DAN SO 01/12/2012 - TK-11052 - added PO to doc category check
 *					JayR 03/21/2012 TK-00000 Change to using table constraint and remove gotos
 *					AJW 7/10/13 TFS-54483 Make sure no reference exists in document tables prior to update
 *
 *--------------------------------------------------------------*/
if @@rowcount = 0 return
set nocount on
DECLARE @errmsg VARCHAR(255)

---- check for changes to DocType
if update(DocType)
       begin
       RAISERROR('Cannot change DocType - cannot update PMDT', 11, -1)
       ROLLBACK TRANSACTION
       RETURN 
       end

-- check for records that have SystemUse flag set to 'Y'
IF EXISTS(SELECT 1 FROM DELETED WHERE SystemUse = 'Y')
BEGIN
	-- cannot change DocCategory
	if update(DocCategory)
	BEGIN
		RAISERROR('Cannot change Document Category for records that are marked for System Use', 11, -1)
		ROLLBACK TRANSACTION
		RETURN 
	END
	
	-- cannot change Active
	if update(Active)
	BEGIN
		IF EXISTS(SELECT 1 FROM inserted WHERE Active = 'N')
		BEGIN
			RAISERROR('Cannot make records Inactive that are marked for System Use', 11, -1)
			ROLLBACK TRANSACTION
			RETURN 
		END
	END
END


-- if changing doccategory check to make sure there are no existing records
IF UPDATE(DocCategory) AND 
	EXISTS(select 1 from deleted d join inserted i on i.KeyID=d.KeyID and i.DocCategory<>d.DocCategory)
BEGIN
	set @errmsg = 'Records exist using this Document Category please correct before changing.'
	--ACO
	IF EXISTS(select 1 from deleted where DocCategory = 'ACO') AND
		EXISTS(select 1 from bPMOH d JOIN deleted i ON i.DocType = d.DocType)
	BEGIN
		RAISERROR(@errmsg, 11, -1)
		ROLLBACK TRANSACTION
		RETURN 
	END
	--CCO
	IF EXISTS(select 1 from deleted where DocCategory = 'CCO') AND
		EXISTS(select 1 FROM vPMContractChangeOrder d JOIN deleted i ON i.DocType = d.DocType)
	BEGIN
		RAISERROR(@errmsg, 11, -1)
		ROLLBACK TRANSACTION
		RETURN 
	END
	--COR
	IF EXISTS(select 1 from deleted where DocCategory = 'COR') AND
		EXISTS(select 1 FROM vPMChangeOrderRequest d JOIN deleted i ON i.DocType = d.DocType)
	BEGIN
		RAISERROR(@errmsg, 11, -1)
		ROLLBACK TRANSACTION
		RETURN 
	END
	--DAILYLOG
	IF EXISTS(select 1 from deleted where DocCategory = 'DAILYLOG') AND
		EXISTS(select 1 FROM bPMDL d JOIN deleted i ON i.DocType = d.DocType)
	BEGIN
		RAISERROR(@errmsg, 11, -1)
		ROLLBACK TRANSACTION
		RETURN 
	END
	--DRAWING
	IF EXISTS(select 1 from deleted where DocCategory = 'DRAWING') AND
		EXISTS(select 1 FROM bPMDG d JOIN deleted i ON i.DocType = d.DrawingType)
	BEGIN
		RAISERROR(@errmsg, 11, -1)
		ROLLBACK TRANSACTION
		RETURN 
	END
	--INSPECT
	IF EXISTS(select 1 from deleted where DocCategory = 'INSPECT') AND
		EXISTS(select 1 FROM bPMIL d JOIN deleted i ON i.DocType = d.InspectionType)
	BEGIN
		RAISERROR(@errmsg, 11, -1)
		ROLLBACK TRANSACTION
		RETURN 
	END
	--ISSUE
	IF EXISTS(select 1 from deleted where DocCategory = 'ISSUE') AND
		EXISTS(select 1 FROM bPMIM d JOIN deleted i ON i.DocType = d.Type)
	BEGIN
		RAISERROR(@errmsg, 11, -1)
		ROLLBACK TRANSACTION
		RETURN 
	END
	--MTG
	IF EXISTS(select 1 from deleted where DocCategory = 'MTG') AND
		EXISTS(select 1 FROM bPMMM d JOIN deleted i ON i.DocType = d.MeetingType)
	BEGIN
		RAISERROR(@errmsg, 11, -1)
		ROLLBACK TRANSACTION
		RETURN 
	END
	--OTHER
	IF EXISTS(select 1 from deleted where DocCategory = 'OTHER') AND
		EXISTS(select 1 FROM bPMOD d JOIN deleted i ON i.DocType = d.DocType)
	BEGIN
		RAISERROR(@errmsg, 11, -1)
		ROLLBACK TRANSACTION
		RETURN 
	END
	--PCO
	IF EXISTS(select 1 from deleted where DocCategory = 'PCO') AND
		EXISTS(select 1 FROM bPMOP d JOIN deleted i ON i.DocType = d.PCOType)
	BEGIN
		RAISERROR(@errmsg, 11, -1)
		ROLLBACK TRANSACTION
		RETURN 
	END
	--POCO
	select * from deleted
	IF EXISTS(select 1 from deleted where DocCategory in ('POCO','PURCHASECO')) AND
		EXISTS(select 1 FROM vPMPOCO d JOIN deleted i ON i.DocType = d.DocType)
	BEGIN
		RAISERROR(@errmsg, 11, -1)
		ROLLBACK TRANSACTION
		RETURN 
	END
	--PUNCH
	IF EXISTS(select 1 from deleted where DocCategory = 'PUNCH') AND
		EXISTS(select 1 FROM bPMPU d JOIN deleted i ON i.DocType = d.DocType)
	BEGIN
		RAISERROR(@errmsg, 11, -1)
		ROLLBACK TRANSACTION
		RETURN 
	END
	--PURCHASE
	IF EXISTS(select 1 from deleted where DocCategory in ('PURCHASE','PO')) AND
		EXISTS(select 1 FROM bPOHD d JOIN deleted i ON i.DocType = d.DocType)
	BEGIN
		RAISERROR(@errmsg, 11, -1)
		ROLLBACK TRANSACTION
		RETURN 
	END
	--REQQUOTE
	IF EXISTS(select 1 from deleted where DocCategory = 'REQQUOTE') AND
		EXISTS(select 1 FROM vPMRequestForQuote d JOIN deleted i ON i.DocType = d.DocType)
	BEGIN
		RAISERROR(@errmsg, 11, -1)
		ROLLBACK TRANSACTION
		RETURN 
	END
	--RFI
	IF EXISTS(select 1 from deleted where DocCategory = 'RFI') AND
		EXISTS(select 1 FROM bPMRI d JOIN deleted i ON i.DocType = d.RFIType)
	BEGIN
		RAISERROR(@errmsg, 11, -1)
		ROLLBACK TRANSACTION
		RETURN 
	END
	--RFQ
	IF EXISTS(select 1 from deleted where DocCategory = 'RFQ') AND
		EXISTS(select 1 FROM bPMRQ d JOIN deleted i ON i.DocType = d.PCOType)
	BEGIN
		RAISERROR(@errmsg, 11, -1)
		ROLLBACK TRANSACTION
		RETURN 
	END
	--SBMTL
	IF EXISTS(select 1 from deleted where DocCategory = 'SBMTL') AND
		EXISTS(select 1 FROM vPMSubmittal d JOIN deleted i ON i.DocType = d.DocumentType)
	BEGIN
		RAISERROR(@errmsg, 11, -1)
		ROLLBACK TRANSACTION
		RETURN 
	END
	--SBMTLPCKG
	IF EXISTS(select 1 from deleted where DocCategory = 'SBMTLPCKG') AND
		EXISTS(select 1 FROM vPMSubmittalPackage d JOIN deleted i ON i.DocType = d.DocType)
	BEGIN
		RAISERROR(@errmsg, 11, -1)
		ROLLBACK TRANSACTION
		RETURN 
	END
	--SUB
	IF EXISTS(select 1 from deleted where DocCategory = 'SUB') AND
		EXISTS(select 1 FROM bSLHD d JOIN deleted i ON i.DocType = d.DocType)
	BEGIN
		RAISERROR(@errmsg, 11, -1)
		ROLLBACK TRANSACTION
		RETURN 
	END
	--SUBCO
	IF EXISTS(select 1 from deleted where DocCategory = 'SUBCO') AND
		EXISTS(select 1 FROM vPMSubcontractCO d JOIN deleted i ON i.DocType = d.DocType)
	BEGIN
		RAISERROR(@errmsg, 11, -1)
		ROLLBACK TRANSACTION
		RETURN 
	END
	--SUBMIT
	IF EXISTS(select 1 from deleted where DocCategory = 'SUBMIT') AND
		EXISTS(select 1 FROM bPMSM d JOIN deleted i ON i.DocType = d.SubmittalType)
	BEGIN
		RAISERROR(@errmsg, 11, -1)
		ROLLBACK TRANSACTION
		RETURN 
	END
	--TEST
	IF EXISTS(select 1 from deleted where DocCategory = 'TEST') AND
		EXISTS(select 1 FROM bPMTL d JOIN deleted i ON i.DocType = d.TestType)
	BEGIN
		RAISERROR(@errmsg, 11, -1)
		ROLLBACK TRANSACTION
		RETURN 
	END
	--TRANSMIT
	IF EXISTS(select 1 from deleted where DocCategory = 'TRANSMIT') AND
		EXISTS(select 1 FROM bPMTM d JOIN deleted i ON i.DocType = d.DocType)
	BEGIN
		RAISERROR(@errmsg, 11, -1)
		ROLLBACK TRANSACTION
		RETURN 
	END
END

---- HQMA inserts
if update(Description)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMDT', 'Doc Type: ' + isnull(i.DocType,''), null, 'C',
			'Description',  d.Description, i.Description, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.DocType=i.DocType
	where isnull(d.Description,'') <> isnull(i.Description,'')
if update(DocCategory)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMDT', 'Doc Type: ' + isnull(i.DocType,''), null, 'C',
			'DocCategory',  d.DocCategory, i.DocCategory, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.DocType=i.DocType
	where isnull(d.DocCategory,'') <> isnull(i.DocCategory,'')
if update(PCODate1)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMDT', 'Doc Type: ' + isnull(i.DocType,''), null, 'C',
			'PCODate1',  d.PCODate1, i.PCODate1, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.DocType=i.DocType
	where isnull(d.PCODate1,'') <> isnull(i.PCODate1,'')
if update(PCODate2)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMDT', 'Doc Type: ' + isnull(i.DocType,''), null, 'C',
			'PCODate2',  d.PCODate2, i.PCODate2, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.DocType=i.DocType
	where isnull(d.PCODate2,'') <> isnull(i.PCODate2,'')
if update(PCODate3)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMDT', 'Doc Type: ' + isnull(i.DocType,''), null, 'C',
			'PCODate3',  d.PCODate3, i.PCODate3, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.DocType=i.DocType
	where isnull(d.PCODate3,'') <> isnull(i.PCODate3,'')
if update(PCOItemDate1)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMDT', 'Doc Type: ' + isnull(i.DocType,''), null, 'C',
			'PCOItemDate1',  d.PCOItemDate1, i.PCOItemDate1, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.DocType=i.DocType
	where isnull(d.PCOItemDate1,'') <> isnull(i.PCOItemDate1,'')
if update(PCOItemDate2)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMDT', 'Doc Type: ' + isnull(i.DocType,''), null, 'C',
			'PCOItemDate2',  d.PCOItemDate2, i.PCOItemDate2, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.DocType=i.DocType
	where isnull(d.PCOItemDate2,'') <> isnull(i.PCOItemDate2,'')
if update(PCOItemDate3)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMDT', 'Doc Type: ' + isnull(i.DocType,''), null, 'C',
			'PCOItemDate3',  d.PCOItemDate3, i.PCOItemDate3, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.DocType=i.DocType
	where isnull(d.PCOItemDate3,'') <> isnull(i.PCOItemDate3,'')
if update(Active)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMDT', 'Doc Type: ' + isnull(i.DocType,''), null, 'C',
			'Active',  d.Active, i.Active, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.DocType=i.DocType
	where isnull(d.Active,'') <> isnull(i.Active,'')
if update(IncludeInProj)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMDT', 'Doc Type: ' + isnull(i.DocType,''), null, 'C',
			'IncludeInProj',  d.IncludeInProj, i.IncludeInProj, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.DocType=i.DocType
	where isnull(d.IncludeInProj,'') <> isnull(i.IncludeInProj,'')
if update(ShowPCOItemDate1)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMDT', 'Doc Type: ' + isnull(i.DocType,''), null, 'C',
			'ShowPCOItemDate1',  d.ShowPCOItemDate1, i.ShowPCOItemDate1, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.DocType=i.DocType
	where isnull(d.ShowPCOItemDate1,'') <> isnull(i.ShowPCOItemDate1,'')
if update(ShowPCOItemDate2)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMDT', 'Doc Type: ' + isnull(i.DocType,''), null, 'C',
			'ShowPCOItemDate2',  d.ShowPCOItemDate2, i.ShowPCOItemDate2, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.DocType=i.DocType
	where isnull(d.ShowPCOItemDate2,'') <> isnull(i.ShowPCOItemDate2,'')
if update(ShowPCOItemDate3)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMDT', 'Doc Type: ' + isnull(i.DocType,''), null, 'C',
			'ShowPCOItemDate3',  d.ShowPCOItemDate3, i.ShowPCOItemDate3, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.DocType=i.DocType
	where isnull(d.ShowPCOItemDate3,'') <> isnull(i.ShowPCOItemDate3,'')
if update(ShowPCODate1)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMDT', 'Doc Type: ' + isnull(i.DocType,''), null, 'C',
			'ShowPCODate1',  d.ShowPCODate1, i.ShowPCODate1, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.DocType=i.DocType
	where isnull(d.ShowPCODate1,'') <> isnull(i.ShowPCODate1,'')
if update(ShowPCODate2)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMDT', 'Doc Type: ' + isnull(i.DocType,''), null, 'C',
			'ShowPCODate2',  d.ShowPCODate2, i.ShowPCODate2, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.DocType=i.DocType
	where isnull(d.ShowPCODate2,'') <> isnull(i.ShowPCODate2,'')
if update(ShowPCODate3)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMDT', 'Doc Type: ' + isnull(i.DocType,''), null, 'C',
			'ShowPCODate3',  d.ShowPCODate3, i.ShowPCODate3, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.DocType=i.DocType
	where isnull(d.ShowPCODate3,'') <> isnull(i.ShowPCODate3,'')
if update(IntExtDefault)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMDT', 'Doc Type: ' + isnull(i.DocType,''), null, 'C',
			'IntExtDefault',  d.IntExtDefault, i.IntExtDefault, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.DocType=i.DocType
	where isnull(d.IntExtDefault,'') <> isnull(i.IntExtDefault,'')
if update(InitAddons)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMDT', 'Doc Type: ' + isnull(i.DocType,''), null, 'C',
			'InitAddons',  d.InitAddons, i.InitAddons, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.DocType=i.DocType
	where isnull(d.InitAddons,'') <> isnull(i.InitAddons,'')
	
---- B-02849
if update(BudgetType)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMDT', 'Doc Type: ' + isnull(i.DocType,''), null, 'C',
			'BudgetType',  d.BudgetType, i.BudgetType, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.DocType=i.DocType
	where isnull(d.BudgetType,'') <> isnull(i.BudgetType,'')
if update(SubType)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMDT', 'Doc Type: ' + isnull(i.DocType,''), null, 'C',
			'SubType',  d.SubType, i.SubType, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.DocType=i.DocType
	where isnull(d.SubType,'') <> isnull(i.SubType,'')
if update(POType)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMDT', 'Doc Type: ' + isnull(i.DocType,''), null, 'C',
			'POType',  d.POType, i.POType, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.DocType=i.DocType
	where isnull(d.POType,'') <> isnull(i.POType,'')
if update(ContractType)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMDT', 'Doc Type: ' + isnull(i.DocType,''), null, 'C',
			'ContractType',  d.ContractType, i.ContractType, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.DocType=i.DocType
	where isnull(d.ContractType,'') <> isnull(i.ContractType,'')
if UPDATE(PriceMethod)
	insert into bHQMA(TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, DateTime, UserName)
	select 'bPMDT', 'Doc Type: ' + isnull(i.DocType,''), null, 'C',
			'PriceMethod',  d.PriceMethod, i.PriceMethod, getdate(), SUSER_SNAME()
	from inserted i join deleted d on d.DocType=i.DocType
	where isnull(d.PriceMethod,'') <> isnull(i.PriceMethod,'')


RETURN 

GO

ALTER TABLE [dbo].[bPMDT] ADD CONSTRAINT [CK_bPMDT_BudgetType] CHECK (([BudgetType]='Y' OR [BudgetType]='N'))
GO
ALTER TABLE [dbo].[bPMDT] ADD CONSTRAINT [CK_bPMDT_ContractType] CHECK (([ContractType]='Y' OR [ContractType]='N'))
GO

ALTER TABLE [dbo].[bPMDT] ADD CONSTRAINT [CK_bPMDT_IntExtDefault] CHECK (([IntExtDefault]='I' OR [IntExtDefault]='E' OR [IntExtDefault]='N'))
GO
ALTER TABLE [dbo].[bPMDT] ADD CONSTRAINT [CK_bPMDT_POType] CHECK (([POType]='Y' OR [POType]='N'))
GO
ALTER TABLE [dbo].[bPMDT] ADD CONSTRAINT [CK_bPMDT_PriceMethod] CHECK (([PriceMethod]='U' OR [PriceMethod]='L'))
GO
ALTER TABLE [dbo].[bPMDT] ADD CONSTRAINT [CK_bPMDT_SubType] CHECK (([SubType]='Y' OR [SubType]='N'))
GO
ALTER TABLE [dbo].[bPMDT] ADD CONSTRAINT [PK_bPMDT] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biPMDT] ON [dbo].[bPMDT] ([DocType]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bPMDT] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPMDT].[ShowPCODate1]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPMDT].[ShowPCODate2]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPMDT].[ShowPCODate3]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPMDT].[ShowPCOItemDate1]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPMDT].[ShowPCOItemDate2]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPMDT].[ShowPCOItemDate3]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPMDT].[IncludeInProj]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bPMDT].[Active]'
GO
