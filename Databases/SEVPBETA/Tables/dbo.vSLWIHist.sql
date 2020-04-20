CREATE TABLE [dbo].[vSLWIHist]
(
[SLCo] [dbo].[bCompany] NOT NULL,
[UserName] [dbo].[bVPUserName] NOT NULL,
[SL] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[SLItem] [dbo].[bItem] NOT NULL,
[ItemType] [tinyint] NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[PhaseGroup] [dbo].[bGroup] NOT NULL,
[Phase] [dbo].[bPhase] NOT NULL,
[UM] [dbo].[bUM] NOT NULL,
[CurUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_vSLWIHist_CurUnits] DEFAULT ((0)),
[CurUnitCost] [dbo].[bUnitCost] NOT NULL CONSTRAINT [DF_vSLWIHist_CurUnitCost] DEFAULT ((0)),
[CurCost] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_vSLWIHist_CurCost] DEFAULT ((0)),
[PrevWCUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_vSLWIHist_PrevWCUnits] DEFAULT ((0)),
[PrevWCCost] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_vSLWIHist_PrevWCCost] DEFAULT ((0)),
[WCUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_vSLWIHist_WCUnits] DEFAULT ((0)),
[WCCost] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_vSLWIHist_WCCost] DEFAULT ((0)),
[WCRetPct] [dbo].[bPct] NOT NULL CONSTRAINT [DF_vSLWIHist_WCRetPct] DEFAULT ((0)),
[WCRetAmt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_vSLWIHist_WCRetAmt] DEFAULT ((0)),
[PrevSM] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_vSLWIHist_PrevSM] DEFAULT ((0)),
[Purchased] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_vSLWIHist_Purchased] DEFAULT ((0)),
[Installed] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_vSLWIHist_Installed] DEFAULT ((0)),
[SMRetPct] [dbo].[bPct] NOT NULL CONSTRAINT [DF_vSLWIHist_SMRetPct] DEFAULT ((0)),
[SMRetAmt] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_vSLWIHist_SMRetAmt] DEFAULT ((0)),
[LineDesc] [dbo].[bItemDesc] NULL,
[VendorGroup] [dbo].[bGroup] NOT NULL,
[Supplier] [dbo].[bVendor] NULL,
[BillMonth] [dbo].[bMonth] NULL,
[BillNumber] [int] NULL,
[BillChangedYN] [dbo].[bYN] NULL,
[WCPctComplete] [dbo].[bPct] NULL,
[WCToDate] [dbo].[bDollar] NULL,
[WCToDateUnits] [dbo].[bUnits] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[ReasonCode] [dbo].[bReasonCode] NULL,
[SLKeyID] [bigint] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.vtSLWIHisti    Script Date:  ******/
CREATE trigger [dbo].[vtSLWIHisti] on [dbo].[vSLWIHist] for INSERT as

/***  basic declares for SQL Triggers ****/
declare @numrows int, @validcnt int, @validcnt2 int, @errmsg varchar(60)

/*--------------------------------------------------------------
*  Insert trigger for SLWIHist
*
*  Created By:  TJL 03/06/09 - Issue #129889, SL Claims and Certifications
*  Modified: 
*
*
*
*  Duplicated Validation as in bSLWI insert
*  
* 
*--------------------------------------------------------------*/

 select @numrows = @@rowcount
 if @numrows = 0 return
 set nocount on
   
/* validate that SL Company and Subcontract exists in bSLWH */
select @validcnt = count(*) from bSLWH c join inserted i on c.SLCo = i.SLCo and c.SL = i.SL
if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Missing Subcontract Header '
   	goto error
   	end
   
/* validate SL */
select @validcnt = count(*) from bSLHD c join inserted i on c.SLCo = i.SLCo and c.SL = i.SL
   where (c.Status = 0 or c.Status = 3)
if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Subcontract.  Must be open or pending  '
   	goto error
   	end
   
/* validate SL Item */
select @validcnt = count(*) from bSLIT  c
join inserted i on c.SLCo = i.SLCo and c.SL = i.SL and c.SLItem = i.SLItem
if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Subcontract Item. '
   	goto error
   	end

return
   
error:
   select @errmsg = @errmsg + ' - cannot insert SL Worksheet Items History'
   RAISERROR(@errmsg, 11, -1);
   rollback transaction
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.vtSLWIHistu    Script Date:  ******/
CREATE trigger [dbo].[vtSLWIHistu] on [dbo].[vSLWIHist] for UPDATE as
/*--------------------------------------------------------------
*  Update trigger for SLWIHist
*
*  Created By:  TJL 03/06/09 - Issue #129889, SL Claims and Certifications
*  Modified: 
*
*
*
*  Duplicated Validation as in bSLWI update
*  
* 
*--------------------------------------------------------------*/

declare @numrows int, @errmsg varchar(255), @validcnt int, @validcnt2 int

select @numrows = @@rowcount
if @numrows = 0 return
set nocount on
   
-- check for key changes
select @validcnt = count(*) from deleted d
	join inserted i on i.SLCo=d.SLCo and i.SL=d.SL and i.SLItem=d.SLItem
if @validcnt <> @numrows
	begin
	select @errmsg = 'Cannot change Primary key'
	goto error
	end
   
-- make sure ItemType value is 1, 2, 3 or 4
select @validcnt = count(*) from inserted
	where ItemType = 1 or ItemType = 2 or ItemType = 3 or ItemType = 4
if @validcnt <> @numrows
	begin
	select @errmsg = 'Item Type must be 1, 2, 3 or 4 '
	goto error
	end
   
/* validate PhaseGroup and Phase */
/*select @validcnt = count(*) from bJCPM c join inserted i on c.PhaseGroup = i.PhaseGroup and c.Phase = i.Phase
if @validcnt <> @numrows
   	begin
   	select @errmsg = 'Invalid Phase Group/Phase  '
   	goto error
   	end*/
   
/* validate UM */
select @validcnt = count(*) from bHQUM r
	join inserted i on i.UM = r.UM
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid Unit of Measure '
	goto error
	end
   
-- validate Supplier in bAPVM
select @validcnt2 = count(*) from inserted where Supplier is null
select @validcnt = count(*) from bAPVM c
join inserted i on c.VendorGroup = i.VendorGroup and c.Vendor = i.Supplier
where i.Supplier is not null
if @validcnt + @validcnt2 <> @numrows
	begin
	select @errmsg = 'Invalid Supplier '
	goto error
	end

return
   
error:
	select @errmsg = @errmsg + ' - cannot update SL Worksheet Item History'
	RAISERROR(@errmsg, 11, -1);
	rollback transaction

   
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [viKeyID] ON [dbo].[vSLWIHist] ([KeyID]) ON [PRIMARY]
GO
