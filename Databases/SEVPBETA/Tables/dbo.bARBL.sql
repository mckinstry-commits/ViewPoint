CREATE TABLE [dbo].[bARBL]
(
[Co] [dbo].[bCompany] NOT NULL,
[Mth] [dbo].[bMonth] NOT NULL,
[BatchId] [dbo].[bBatchID] NOT NULL,
[BatchSeq] [int] NOT NULL,
[ARLine] [smallint] NULL,
[TransType] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[ARTrans] [dbo].[bTrans] NULL,
[RecType] [tinyint] NULL,
[LineType] [char] (1) COLLATE Latin1_General_BIN NULL,
[Description] [dbo].[bDesc] NULL,
[GLCo] [dbo].[bCompany] NULL,
[GLAcct] [dbo].[bGLAcct] NULL,
[TaxGroup] [dbo].[bGroup] NULL,
[TaxCode] [dbo].[bTaxCode] NULL,
[Amount] [dbo].[bDollar] NULL,
[TaxBasis] [dbo].[bDollar] NULL,
[TaxAmount] [dbo].[bDollar] NULL,
[RetgPct] [dbo].[bPct] NULL,
[Retainage] [dbo].[bDollar] NULL,
[DiscOffered] [dbo].[bDollar] NULL,
[TaxDisc] [dbo].[bDollar] NOT NULL,
[DiscTaken] [dbo].[bDollar] NULL,
[CreditTaxAmt] [dbo].[bDollar] NULL,
[AddRetainage] [dbo].[bDollar] NULL,
[ApplyMth] [dbo].[bMonth] NULL,
[ApplyTrans] [dbo].[bTrans] NULL,
[ApplyLine] [smallint] NULL,
[JCCo] [dbo].[bCompany] NULL,
[Contract] [dbo].[bContract] NULL,
[Item] [dbo].[bContractItem] NULL,
[ContractUnits] [dbo].[bUnits] NULL,
[Job] [dbo].[bJob] NULL,
[PhaseGroup] [dbo].[bGroup] NULL,
[Phase] [dbo].[bPhase] NULL,
[CostType] [dbo].[bJCCType] NULL,
[UM] [dbo].[bUM] NULL,
[JobUnits] [dbo].[bUnits] NULL,
[JobHours] [dbo].[bHrs] NULL,
[ActDate] [dbo].[bDate] NULL,
[INCo] [dbo].[bCompany] NULL,
[Loc] [dbo].[bLoc] NULL,
[MatlGroup] [dbo].[bGroup] NULL,
[Material] [dbo].[bMatl] NULL,
[UnitPrice] [dbo].[bUnitCost] NULL,
[ECM] [dbo].[bECM] NULL,
[MatlUnits] [dbo].[bUnits] NULL,
[CustJob] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[CustPO] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[EMCo] [dbo].[bCompany] NULL,
[Equipment] [dbo].[bEquip] NULL,
[EMGroup] [dbo].[bGroup] NULL,
[CostCode] [dbo].[bCostCode] NULL,
[EMCType] [dbo].[bEMCType] NULL,
[oldRecType] [tinyint] NULL,
[oldLineType] [char] (1) COLLATE Latin1_General_BIN NULL,
[oldDescription] [dbo].[bDesc] NULL,
[oldGLCo] [dbo].[bCompany] NULL,
[oldGLAcct] [dbo].[bGLAcct] NULL,
[oldTaxGroup] [dbo].[bGroup] NULL,
[oldTaxCode] [dbo].[bTaxCode] NULL,
[oldAmount] [dbo].[bDollar] NULL,
[oldTaxBasis] [dbo].[bDollar] NULL,
[oldTaxAmount] [dbo].[bDollar] NULL,
[oldRetgPct] [dbo].[bPct] NULL,
[oldRetainage] [dbo].[bDollar] NULL,
[oldDiscOffered] [dbo].[bDollar] NULL,
[oldTaxDisc] [dbo].[bDollar] NULL,
[oldDiscTaken] [dbo].[bDollar] NULL,
[oldApplyMth] [dbo].[bMonth] NULL,
[oldApplyTrans] [dbo].[bTrans] NULL,
[oldApplyLine] [smallint] NULL,
[oldJCCo] [dbo].[bCompany] NULL,
[oldContract] [dbo].[bContract] NULL,
[oldItem] [dbo].[bContractItem] NULL,
[oldContractUnits] [dbo].[bUnits] NULL,
[oldJob] [dbo].[bJob] NULL,
[oldPhaseGroup] [dbo].[bGroup] NULL,
[oldPhase] [dbo].[bPhase] NULL,
[oldCostType] [dbo].[bJCCType] NULL,
[oldUM] [dbo].[bUM] NULL,
[oldJobUnits] [dbo].[bUnits] NULL,
[oldJobHours] [dbo].[bHrs] NULL,
[oldActDate] [dbo].[bDate] NULL,
[oldINCo] [dbo].[bCompany] NULL,
[oldLoc] [dbo].[bLoc] NULL,
[oldMatlGroup] [dbo].[bGroup] NULL,
[oldMaterial] [dbo].[bMatl] NULL,
[oldUnitPrice] [dbo].[bUnitCost] NULL,
[oldECM] [dbo].[bECM] NULL,
[oldMatlUnits] [dbo].[bUnits] NULL,
[oldCustJob] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[oldCustPO] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[oldEMGroup] [dbo].[bGroup] NULL,
[oldEMCo] [dbo].[bCompany] NULL,
[oldEquipment] [dbo].[bEquip] NULL,
[oldCostCode] [dbo].[bCostCode] NULL,
[oldEMCType] [dbo].[bEMCType] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[oldNotes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[CompType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Component] [dbo].[bEquip] NULL,
[oldCompType] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[oldComponent] [dbo].[bEquip] NULL,
[FinanceChg] [dbo].[bDollar] NULL,
[rptApplyMth] [dbo].[bMonth] NULL,
[rptApplyTrans] [dbo].[bTrans] NULL,
[oldFinanceChg] [dbo].[bDollar] NULL,
[oldrptApplyMth] [dbo].[bMonth] NULL,
[oldrptApplyTrans] [dbo].[bTrans] NULL,
[RetgTax] [dbo].[bDollar] NULL,
[oldRetgTax] [dbo].[bDollar] NULL,
[SMWorkCompletedID] [bigint] NULL,
[SMAgreementBillingScheduleID] [bigint] NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
   
/****** Object:  Trigger dbo.btARBLi    Script Date: 8/28/99 9:37:01 AM ******/
CREATE  trigger [dbo].[btARBLi] on [dbo].[bARBL] for insert as

/*-----------------------------------------------------------------
*   This trigger rejects insert in bARBL
*    if the following error condition exists:
*
*   Author: CJW  Oct  1 1997  9:18AM
*-----------------------------------------------------------------*/
  
declare @errmsg varchar(255), @validcnt int, @errno int, @numrows int, @nullcnt int

select @numrows = @@rowcount

set nocount on

if @numrows = 0 return

/* Set HQCC Close Control entry.  This might be an AR GLCo entry or can also be
   a JC GLCo Cross Company Revenue entry, typically from InvoiceEntry.  */
insert into bHQCC(Co, Mth, BatchId, GLCo)
select distinct Co, Mth, BatchId, GLCo 
from inserted i
where not exists(select * from bHQCC c where c.Co=i.Co and c.Mth=i.Mth
	and c.BatchId=i.BatchId and c.GLCo=i.GLCo) and i.GLCo is not null
   
return

error:
   
select @errmsg = @errmsg + ' - cannot insert into bARBL!'
   
RAISERROR(@errmsg, 11, -1);
   
rollback transaction
   
   
  
 




GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 
  
   
   
   
   /****** Object:  Trigger dbo.btARBLu    Script Date: 8/28/99 9:37:01 AM ******/
   CREATE  trigger [dbo].[btARBLu] on [dbo].[bARBL] for update as 

/*-----------------------------------------------------------------
*   This trigger rejects insert in bARBL
*    if the following error condition exists:
*
*   Author: CJW  Oct  1 1997  9:18AM
*	Modified By:  TJL  02/14/08 - Issue #126898, GLCo may be empty from ARRelease, Don't update HQCC
*
*-----------------------------------------------------------------*/

declare @errmsg varchar(255), @validcnt int, @errno int, @numrows int, @nullcnt int
declare @co bCompany, @mth bMonth, @batchid bBatchID, @newglco bCompany

select @numrows = @@rowcount

if @numrows = 0 return

set nocount on

insert into bHQCC(Co, Mth, BatchId, GLCo)
select distinct Co, Mth, BatchId, GLCo 
from inserted i 
where not exists(select * from bHQCC c where c.Co=i.Co and c.Mth=i.Mth
	and c.BatchId=i.BatchId and c.GLCo=i.GLCo) and i.GLCo is not null
   
return

error:

select @errmsg = @errmsg + ' - cannot update bARBL!'
RAISERROR(@errmsg, 11, -1);
rollback transaction
   
   
  
 



GO
CREATE NONCLUSTERED INDEX [biARBLApplied] ON [dbo].[bARBL] ([Co], [ApplyMth], [ApplyTrans], [ApplyLine], [Mth], [BatchId], [BatchSeq]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biARBL] ON [dbo].[bARBL] ([Co], [Mth], [BatchId], [BatchSeq], [ARLine]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bARBL].[TaxDisc]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bARBL].[UnitPrice]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bARBL].[ECM]'
GO
EXEC sp_bindefault N'[dbo].[bdZero]', N'[dbo].[bARBL].[oldUnitPrice]'
GO
EXEC sp_bindrule N'[dbo].[brECM]', N'[dbo].[bARBL].[oldECM]'
GO
