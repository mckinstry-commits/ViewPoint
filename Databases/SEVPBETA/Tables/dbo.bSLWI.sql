CREATE TABLE [dbo].[bSLWI]
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
[CurUnits] [dbo].[bUnits] NOT NULL,
[CurUnitCost] [dbo].[bUnitCost] NOT NULL,
[CurCost] [dbo].[bDollar] NOT NULL,
[PrevWCUnits] [dbo].[bUnits] NOT NULL,
[PrevWCCost] [dbo].[bDollar] NOT NULL,
[WCUnits] [dbo].[bUnits] NOT NULL,
[WCCost] [dbo].[bDollar] NOT NULL,
[WCRetPct] [dbo].[bPct] NOT NULL,
[WCRetAmt] [dbo].[bDollar] NOT NULL,
[PrevSM] [dbo].[bDollar] NOT NULL,
[Purchased] [dbo].[bDollar] NOT NULL,
[Installed] [dbo].[bDollar] NOT NULL,
[SMRetPct] [dbo].[bPct] NOT NULL,
[SMRetAmt] [dbo].[bDollar] NOT NULL,
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
[UnitsClaimed] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bSLWI_UnitsClaimed] DEFAULT ((0)),
[AmtClaimed] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bSLWI_AmtClaimed] DEFAULT ((0)),
[ReasonCode] [dbo].[bReasonCode] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
   
   CREATE   TRIGGER [dbo].[btSLWId] ON [dbo].[bSLWI] FOR DELETE AS    
/*-----------------------------------------------------------------
    *Created:  	DC  03/16/2009
    *			
    *
    * Delete trigger for bSLWI:
    *	-Delete the associated SLWIInvoices records.
	*
    */----------------------------------------------------------------
    DECLARE @errmsg varchar(255)    
    
    SET NOCOUNT ON      
    
    DELETE SLWIInvoices
    FROM SLWIInvoices i
    Join Deleted d on d.SLCo = i.SLCo and d.SL = i.SL and d.SLItem = i.SLItem          	

    RETURN
    


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   /****** Object:  Trigger dbo.btSLWIi    Script Date: 8/28/99 9:38:17 AM ******/
   
    CREATE trigger [dbo].[btSLWIi] on [dbo].[bSLWI] for INSERT as
   
     

/***  basic declares for SQL Triggers ****/
    declare @numrows int, @validcnt int, @validcnt2 int, @errmsg varchar(60)
    /*--------------------------------------------------------------
     *  Insert trigger for SLWI
     *  Created By: EN  3/28/00
     *  Modified:	GG 07/19/00 - changed validation to check Item in bSLIT
     *
     *  Validate that SL Co# and Subcontract exist in bSLWH.
     *  Validate that Subcontract and Item exist in bSLHD and bSLIT
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
       select @errmsg = @errmsg + ' - cannot insert SL Worksheet Items'
       RAISERROR(@errmsg, 11, -1);
       rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   /****** Object:  Trigger dbo.btSLWIu    Script Date: 8/28/99 9:38:18 AM ******/
   
   CREATE trigger [dbo].[btSLWIu] on [dbo].[bSLWI] for UPDATE as
   

/*--------------------------------------------------------------
    *
    *  Update trigger for SLWI
    *  Created: EN 3/28/00
    *  Modified : DANF 08/03/00 removed incorrect phase validation
    *
    *  Reject primary key changes.
    *  ItemType must be 1, 2, 3, or 4.
    *  Validate PhaseGroup and Phase.
    *  Validate UM.
    *  Validate Supplier.
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
      select @errmsg = @errmsg + ' - cannot update SL Worksheet Item'
      RAISERROR(@errmsg, 11, -1);
      rollback transaction
   
   
   
  
 



GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bSLWI] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biSLWI] ON [dbo].[bSLWI] ([SLCo], [UserName], [SL], [SLItem]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bSLWI].[CurUnitCost]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bSLWI].[BillChangedYN]'
GO
