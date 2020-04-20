CREATE TABLE [dbo].[bJBIN]
(
[JBCo] [dbo].[bCompany] NULL,
[BillMonth] [dbo].[bMonth] NOT NULL,
[BillNumber] [int] NOT NULL,
[Invoice] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[Contract] [dbo].[bContract] NULL,
[CustGroup] [dbo].[bGroup] NOT NULL,
[Customer] [dbo].[bCustomer] NOT NULL,
[InvStatus] [char] (1) COLLATE Latin1_General_BIN NOT NULL,
[Application] [smallint] NULL,
[ProcessGroup] [varchar] (20) COLLATE Latin1_General_BIN NULL,
[RestrictBillGroupYN] [dbo].[bYN] NOT NULL,
[BillGroup] [dbo].[bBillingGroup] NULL,
[RecType] [tinyint] NOT NULL,
[DueDate] [dbo].[bDate] NOT NULL,
[InvDate] [dbo].[bDate] NOT NULL,
[PayTerms] [dbo].[bPayTerms] NULL,
[DiscDate] [dbo].[bDate] NULL,
[FromDate] [dbo].[bDate] NULL,
[ToDate] [dbo].[bDate] NULL,
[BillAddress] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[BillAddress2] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[BillCity] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[BillState] [varchar] (4) COLLATE Latin1_General_BIN NULL,
[BillZip] [dbo].[bZip] NULL,
[ARTrans] [dbo].[bTrans] NULL,
[InvTotal] [dbo].[bDollar] NOT NULL,
[InvRetg] [dbo].[bDollar] NOT NULL,
[RetgRel] [dbo].[bDollar] NOT NULL,
[InvDisc] [dbo].[bDollar] NOT NULL,
[TaxBasis] [dbo].[bDollar] NOT NULL,
[InvTax] [dbo].[bDollar] NOT NULL,
[InvDue] [dbo].[bDollar] NOT NULL,
[PrevAmt] [dbo].[bDollar] NOT NULL,
[PrevRetg] [dbo].[bDollar] NOT NULL,
[PrevRRel] [dbo].[bDollar] NOT NULL,
[PrevTax] [dbo].[bDollar] NOT NULL,
[PrevDue] [dbo].[bDollar] NOT NULL,
[ARRelRetgTran] [dbo].[bTrans] NULL,
[ARRelRetgCrTran] [dbo].[bTrans] NULL,
[ARGLCo] [dbo].[bCompany] NOT NULL,
[JCGLCo] [dbo].[bCompany] NOT NULL,
[CurrContract] [dbo].[bDollar] NOT NULL,
[PrevWC] [dbo].[bDollar] NOT NULL,
[WC] [dbo].[bDollar] NOT NULL,
[PrevSM] [dbo].[bDollar] NOT NULL,
[Installed] [dbo].[bDollar] NOT NULL,
[Purchased] [dbo].[bDollar] NOT NULL,
[SM] [dbo].[bDollar] NOT NULL,
[SMRetg] [dbo].[bDollar] NOT NULL,
[PrevSMRetg] [dbo].[bDollar] NOT NULL,
[PrevWCRetg] [dbo].[bDollar] NOT NULL,
[WCRetg] [dbo].[bDollar] NOT NULL,
[PrevChgOrderAdds] [dbo].[bDollar] NOT NULL,
[PrevChgOrderDeds] [dbo].[bDollar] NOT NULL,
[ChgOrderAmt] [dbo].[bDollar] NOT NULL,
[AutoInitYN] [dbo].[bYN] NOT NULL,
[InUseBatchId] [dbo].[bBatchID] NULL,
[InUseMth] [dbo].[bMonth] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[BillOnCompleteYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJBIN_BillOnCompleteYN] DEFAULT ('N'),
[BillType] [char] (1) COLLATE Latin1_General_BIN NOT NULL CONSTRAINT [DF_bJBIN_BillType] DEFAULT ('P'),
[Template] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[CustomerReference] [dbo].[bDesc] NULL,
[CustomerJob] [dbo].[bDesc] NULL,
[ACOThruDate] [dbo].[bDate] NULL,
[Purge] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJBIN_Purge] DEFAULT ('N'),
[AuditYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJBIN_AuditYN] DEFAULT ('Y'),
[OverrideGLRevAcctYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJBIN_OverrideGLRevAcctYN] DEFAULT ('N'),
[OverrideGLRevAcct] [dbo].[bGLAcct] NULL,
[UniqueAttchID] [uniqueidentifier] NULL,
[RevRelRetgYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJBIN_RevRelRetgYN] DEFAULT ('N'),
[InvDescription] [dbo].[bDesc] NULL,
[TMUpdateAddonYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJBIN_TMUpdateAddonYN] DEFAULT ('Y'),
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[BillCountry] [char] (2) COLLATE Latin1_General_BIN NULL,
[RetgTax] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJBIN_RetgTax] DEFAULT ((0.00)),
[PrevRetgTax] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJBIN_PrevRetgTax] DEFAULT ((0.00)),
[RetgTaxRel] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJBIN_RetgTaxRel] DEFAULT ((0.00)),
[PrevRetgTaxRel] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJBIN_PrevRetgTaxRel] DEFAULT ((0.00)),
[CertifiedDate] [dbo].[bDate] NULL,
[AmtClaimed] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJBIN_AmtClaimed] DEFAULT ((0.00)),
[ClaimDate] [dbo].[bDate] NULL,
[Certified] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJBIN_Certified] DEFAULT ('N'),
[CreatedBy] [dbo].[bVPUserName] NULL,
[CreatedDate] [dbo].[bDate] NULL,
[InitOption] [char] (1) COLLATE Latin1_General_BIN NULL,
[udSource] [varchar] (30) COLLATE Latin1_General_BIN NULL,
[udConv] [varchar] (1) COLLATE Latin1_General_BIN NULL,
[udCGCTable] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[udCGCTableID] [decimal] (12, 0) NULL
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btJBINi    Script Date: 8/28/99 9:37:37 AM ******/
CREATE trigger [dbo].[btJBINd] on [dbo].[bJBIN] for DELETE as

/*-----------------------------------------------------------------
*   Created by: kb 9/22/99
* 	Modified by: kb 5/24/00 - add delete of JBJE records
*   	bc 01/04/00 - delete JBMD
*		allenn 06/06/01 - include code to add HQ Master Audit entry
*		allenn 07/26/01 - edited code to add HQ Master Audit entry issue #13667
*    	ALLENN 11/16/2001 Issue #13667
*   	kb 2/19/2 - issue #16147
*		kb 8/5/2 - issue #18055
*		TJL 10/24/02 - Issue #18907, delete bJBBE if this Bill gets deleted
*		TJL 11/06/02 - Issue #18740, Speedup Purge/Delete process by not performing
*					   unnecessary updates while deleting detail records
*		kb 11/19/2 - issue #19328 - remove debug statement
*		TJL 02/07/03 - Issue #17278, set audit flags on Delete, Purges
*		TJL 12/16/03 - Issue #21076, Update Previous ChgOrder Values automatically
*		TJL 03/15/04 - Issue #24051, Correct Keystring, Converted BillMonth
*		TJL 05/10/04 - Issue #24566, Correct incorrect (convert(varchar(), ____)) statements thru-out
*		TJL 07/30/04 - Issue #25260, Update ChgOrderAdds/Deds by BillGroup
*		TJL 09/15/06 - Issue #122473 (5x - 119946), Prevent JBIS trigger update to Future Bills CurrContract on Bill Purge
*		TJL 05/24/07 - Issue #123155, Allow HQMA auditing when Bill gets deleted regardless of AuditFlag setting in JBCO
*		TJL 03/17/09 - Issue #132707, Interfaced Bills mysteriously being Deleted somehow despite form code preventing this.
*
*	This trigger rejects update in bJBIN (HR Company) if the
*	following error condition exists:
*
*		Invalid HQ Company number
*
*/----------------------------------------------------------------
declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int,
   	@jbco bCompany, @billmth bMonth, @billnum int, @audityn bYN, @rcode int,
   	@prevupdateYN bYN,@invcustgroup bGroup, @invcustomer bCustomer,
   	@invcontract bContract, @invchgorderamt bDollar, @billgroup bBillingGroup
   
select @numrows = @@rowcount, @rcode = 0
if @numrows = 0 return
set nocount on

/* Deletion not allowed if the Billing has been interfaced to AR (ARTrans is not Null) and if this 
   action is not a purge (Bill is being deleted outside the purge routine) */
select @validcnt = count(1) 
from deleted d
where d.ARTrans is not null and d.Purge = 'N' and d.InvStatus <> 'D'
if @validcnt <> 0
	begin
	select @errmsg = 'JB Bill has been Interfaced to AR and cannot be deleted.  Set Inv Status to "D" and reinterface.'
	goto error
	end
  
/* Purge and Audit Flags in JBIN, typically get set by the Purge procedure (bspJBInvoicePurge).
  In turn, JBIN UPDATE trigger sets Purge and Audit flags on all related table records
  to be purged.  (Purge = 'Y', AuditYN = 'N',  No Audits will occur on Purges)

  A single JBIN record delete does not run (bspJBInvoicePurge) and thus Purge flags for
  all related table records will need to be set here.  (Audit will occur on a delete).
  A single record delete could also be a purge, so we must check the JBIN.AuditYN flag 
  and set related table AuditYN flags accordingly.  

  Purge flags are used in the related table triggers for both a Purge or a
  Delete to suspend the normal updates that would usually occur.  Since deleting a 
  Bill Header (JBIN record) deletes all associated JB record detail, typical cascading
  updates should not occur. The AuditYN flag may also be used in conjunction with the
  Purge flag to determine if this is a 'Delete' or 'Purge'.  One example is bJBIT
  delete trigger.

  JB is not standard in that Deleting a Bill Header and its detail is allowed from 
  the standard form Delete button. */

/* First Update related table Purge flag and AuditYN flag if this is a single 
  bill delete. AuditYN setting is determined by the JBIN.AuditYN setting which
  will identify if this is a single record 'Delete' or 'Purge'. Using the Purge flag 
  here will restrict these table triggers from performing further updates to records that 
  are about to be deleted anyway. */
if @numrows = 1
   	begin
   	select @jbco = JBCo, @billmth = BillMonth, @billnum = BillNumber, @audityn = AuditYN,
   		@invcustgroup = CustGroup, @invcustomer = Customer, @invcontract = Contract, 
   		@invchgorderamt = ChgOrderAmt, @billgroup = BillGroup
   	from deleted
   
   	update bJBMD
   	set Purge = 'Y', AuditYN = case when @audityn = 'N' then 'N' else 'Y' end
   	where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnum
   
   	update bJBJE
   	set Purge = 'Y', AuditYN = case when @audityn = 'N' then 'N' else 'Y' end
   	where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnum

   	update bJBIS
   	set Purge = 'Y', AuditYN = case when @audityn = 'N' then 'N' else 'Y' end
   	where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnum

   	update bJBCX
   	set Purge = 'Y', AuditYN = case when @audityn = 'N' then 'N' else 'Y' end
   	where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnum
   
   	update bJBCC
   	set Purge = 'Y', AuditYN = case when @audityn = 'N' then 'N' else 'Y' end
   	where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnum

   	update bJBIT
   	set Purge = 'Y', AuditYN = case when @audityn = 'N' then 'N' else 'Y' end
   	where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnum
   
   	update bJBIL
   	set Purge = 'Y', AuditYN = case when @audityn = 'N' then 'N' else 'Y' end
   	where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnum
   
   	update bJBID
   	set Purge = 'Y', AuditYN = case when @audityn = 'N' then 'N' else 'Y' end
   	where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnum
   
   	update bJBIJ
   	set Purge = 'Y', AuditYN = case when @audityn = 'N' then 'N' else 'Y' end
   	where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnum
	end
   
/* Begin deleting related table detail */
delete bJBMD 
from bJBMD t,deleted d 
where t.JBCo = d.JBCo and t.BillMonth = d.BillMonth and t.BillNumber = d.BillNumber

delete bJBBE 
from bJBBE t,deleted d 
where t.JBCo = d.JBCo and t.BillMonth = d.BillMonth and t.BillNumber = d.BillNumber

delete bJBJE 
from bJBJE t,deleted d
where t.JBCo = d.JBCo and t.BillMonth = d.BillMonth and t.BillNumber = d.BillNumber

delete bJBIS 
from bJBIS t,deleted d 
where t.JBCo = d.JBCo and t.BillMonth = d.BillMonth and t.BillNumber = d.BillNumber

delete bJBCX 
from bJBCX t,deleted d 
where t.JBCo = d.JBCo and t.BillMonth = d.BillMonth and t.BillNumber = d.BillNumber

delete bJBCC 
from bJBCC t,deleted d 
where t.JBCo = d.JBCo and t.BillMonth = d.BillMonth and t.BillNumber = d.BillNumber

delete bJBIT 
from bJBIT t,deleted d 
where t.JBCo = d.JBCo and t.BillMonth = d.BillMonth and t.BillNumber = d.BillNumber
   
delete bJBIL 
from bJBIL t,deleted d 
where t.JBCo = d.JBCo and t.BillMonth = d.BillMonth and t.BillNumber = d.BillNumber

delete bJBID 
from bJBID t,deleted d 
where t.JBCo = d.JBCo and t.BillMonth = d.BillMonth and t.BillNumber = d.BillNumber

delete bJBIJ 
from bJBIJ t, deleted d 
where t.JBCo = d.JBCo and t.BillMonth = d.BillMonth and t.BillNumber = d.BillNumber
   
/* Update Previous ChgOrderAdds/Deds on future bills when Bill is physically deleted. 
  *** Note *** @audityn will only be set to 'Y' when a single bill is being deleted
  from within the JB Bill Header forms.  (Not during a Purge).  When this is the case
  Update Previous does occur for both Billed Item amounts and ChgOrderAdds/Deds. */
if @audityn = 'Y'	--Single Bill Delete
   	begin
   	/* Check Automatic PrevUpdateYN flag. */
   	select @prevupdateYN = PrevUpdateYN
   	from bJBCO with (nolock)
   	where JBCo = @jbco
   	if @prevupdateYN = 'Y'
   		begin
   		exec @rcode = bspJBUpdatePrevChgOrderValues @jbco, @billmth, @billnum, @invcustgroup, @invcustomer,
   			@invcontract, @invchgorderamt, @billgroup, @errmsg output
   		if @rcode = 1 goto error
   		end
   	end
     
/*Isse 13667 (11/16/2001)*/
Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
Select 'bJBIN', 'JBCo: ' + isnull(convert(varchar(3),d.JBCo), '') + 'BillMonth: ' + convert(varchar(8), d.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),d.BillNumber), isnull(d.JBCo, 0), 'D', null, null, null, getdate(), SUSER_SNAME()
From deleted d
Join bJBCO c on c.JBCo = d.JBCo
Where d.AuditYN = 'Y'		--c.AuditBills = 'Y' and

return
error:
select @errmsg = @errmsg + ' - cannot delete JB Progress Bill Header (JBIN)!'
RAISERROR(@errmsg, 11, -1);
rollback transaction
   
   
  
 








GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Trigger dbo.btJBINi    Script Date: 8/28/99 9:37:37 AM ******/
   CREATE  trigger [dbo].[btJBINi] on [dbo].[bJBIN] for INSERT as

/*-----------------------------------------------------------------
* Created:  kb 2/25/99
* Modified: bc 06/01/00
*  		kb 4/14/00 - check for isnumeric when update last invoice.  issue 9517
*    	bc 04/19/00 - readded acothrudate
*   	bc 05/10/00 - rewrote how the previous change order adds & deds are calculated
*    	kb 5/22/00 - changed bBillGroup to be bBillingGroup
*     	bc 09/19/00 - added lastmthsubclosed check
*    	bc 09/27/00 - corrected the select on JBCX to join on the items just added to jbit
*    	bc 11/07/00 - removed restriction in front of bspJBProgressBillItemsInit that only
*                 	  allowed bill types of 'P' to call said procedure
*    	bc 11/29/00 - changed invoice update to JB and AR to have @autoseq in the first If .... Then
*                 	  because having @autoseq in the where clause didn't prevent an unwanted update to ARCO
*	 	allenn 06/06/01 - include code to add HQ Master Audit entry
*     	bc 07/10/01 - issue #13974
*	  	allenn 07/26/01 - edited code to add HQ Master Audit entry issue #13667
*	   	kb 10/22/01 - issue #14971
*     	ALLENN 11/16/2001 Issue #13667
*     	kb 2/19/2 - issue #16147
*     	dhv 8/21/02 - issue #18337 Changed JBCO and ARCO update statements for last invoice number
*		TJL 11/05/02 - Issue #19211, Allow Releasing Retainage on True T&M Bills with Contracts
*		TJL 06/27/03 - Issue #21628, Problem w/#19211 above, reverse 19211 mods
*		TJL 12/16/03 - Issue #21076, Remove old joins, remove psuedo cursors, mod PrevChgOrderAdd/Deds get
*		TJL 03/15/04 - Issue #24051, Correct Keystring, Converted BillMonth
*		TJL 03/15/04 - Issue #24031, Do Not Audit JBCO.LastInvoice, ARCO.InvLastNum from JBIN triggers
*		TJL 05/10/04 - Issue #24566, Correct incorrect (convert(varchar(), ____)) statements thru-out
*		TJL 07/30/04 - Issue #25260, Update ChgOrderAdds/Deds by BillGroup
*		TJL 08/27/04 - Issue #25434, Add isnull() relative to BillGroup
*		TJL 08/30/04 - Issue #25431, Accumulate Adds/Deds by Bill not by Item
*		TJL 09/20/04 - Issue #25399, Fix 25431 above. Accumulate Adds/Deds relative to 
*						the current Bills Items only. (Not by JBIN BillGroup only)
*		TJL 01/26/05 - Issue #26941, Related to #21076.  Fix PrevChgOrderAdds/PrevChgOrderDeds doubling in value
*		TJL 03/07/08 - Issue #127077, International Addresses
*		TJL 03/13/08 - Issue #127452, Trigger error (Invalid TaxCode) being reported incorrectly. 
*		GG 06/16/08 - #128324 - fix Country/State validation 
*		TJL 01/02/09 - Issue #120173, Combine Progress and T&M Auto-Initialization
*		CHS 12/16/2011 - B-08120 - Move bills to next month
*
*  This trigger rejects update in bJBIN (HR Company) if the
*  following error condition exists:
*
*		Invalid HQ Company number
*
*/----------------------------------------------------------------
declare @errmsg varchar(255), @numrows int, @validcnt int, @validcnt2 int

declare @jbco bCompany, @billmth bMonth, @billnum int, @billtype char(1), @arco bCompany,
   	@invoice varchar(10),@invdate bDate, @invstatus char(1),
   	@custgroup bGroup, @customer bCustomer, @contract bContract, 
   	@itembillgroup bBillingGroup, @procgroup varchar(10),   
   	@fromdate bDate, @todate bDate, @acothrudate bDate, 
   	@payterms bPayTerms, @discdate bDate, @duedate bDate, @discrate bPct,
   	@prevchgorderdeds bDollar, @prevchgorderadds bDollar,
   	@rcode tinyint, @autoseq bYN, @invopt char(10), @limitopt char(1),@autoinit bYN,
	@glco bCompany, @lastmthsubclsd bMonth, @openinsertcursor int, @billgroup bBillingGroup,
   	@openPrevBillcursor int, @openPrevACOcursor int, @prevchgorderamt bDollar,
   	@prevbillmth bMonth, @prevbillnumber int, @prevaco bACO, @nullcnt int,	
   	@billinitopt char(1), 
   	@purgeyn bYN, @audityn bYN, @msg varchar(255)
    
select @numrows = @@rowcount, @rcode = 0, @openinsertcursor = 0, @openPrevBillcursor = 0, @openPrevACOcursor = 0	

if @numrows = 0 return

set nocount on
   
--validate JB Company
select @validcnt = count(*) 
from inserted i
join bHQCO h (nolock) on i.JBCo = h.HQCo
if @validcnt <> @numrows
	begin
	select @errmsg = 'Invalid JB Company'
	goto error
	end

--JB Company must be a valid JC Company
select @validcnt = count(*) 
from inserted i
join bJCCO c on i.JBCo =c.JCCo
if @validcnt <> @numrows
	begin
	select @errmsg = 'JB Company not setup in JC'
	goto error
	end
	
--validate Bill Country
select @validcnt = count(1)
from dbo.bHQCountry c (nolock) 
join inserted i on i.BillCountry = c.Country
select @nullcnt = count(1) from inserted where BillCountry is null
if @validcnt + @nullcnt <> @numrows
	begin
	select @errmsg = 'Invalid Bill Country'
	goto error
	end

-- validate Bill Country/State combinations
select @validcnt = count(1) -- Country/State combos are unique
from inserted i
join dbo.bHQCO c (nolock) on c.HQCo = i.JBCo	-- join to get Default Country
join dbo.bHQST s (nolock) on isnull(i.BillCountry,c.DefaultCountry) = s.Country and i.BillState = s.State
select @nullcnt = count(1) from inserted where BillState is null
if @validcnt + @nullcnt <> @numrows
	begin
	select @errmsg = 'Invalid Bill Country and State combination'
	goto error
	end


/* Cycle through inserted which will add the items either initializing from JCCP if the AutoInitYN flag
  is turned on or initializing to zero if it is turned off.*/
declare bcInserted cursor local fast_forward for
select i.JBCo, i.BillMonth, i.BillNumber, Purge, AuditYN
from inserted i with (nolock)
order by i.JBCo, i.BillMonth, i.BillNumber

open bcInserted
select @openinsertcursor = 1

fetch next from bcInserted into @jbco, @billmth, @billnum, @purgeyn, @audityn
while @@fetch_status = 0
   	begin	/* Begin inserted loop */
   	
   	
   	/* Bill Purge, Do NOT update Previous Amounts on Later bills */
	if @purgeyn = 'Y' and @audityn = 'Y'
   			begin
   			if @openinsertcursor = 1
   				begin
   				close bcInserted
   				deallocate bcInserted
   				select @openinsertcursor = 0
   				end
   			goto begin_audit
   			end	
   	
   	
   	
  	select @glco = GLCo
  	from bJCCO with (nolock)
  	where JCCo = @jbco
  	
  	
  	
  	
  	

  	select @lastmthsubclsd = LastMthSubClsd
  	from bGLCO with (nolock)
  	where GLCo = @glco
  	if @billmth <= @lastmthsubclsd
    	begin
    	select @errmsg = 'Month is closed in subledgers '
    	goto error
    	end

   	/* Get info from inserted for this bill*/
   	select @invoice = i.Invoice, @custgroup = i.CustGroup, @customer = i.Customer, @contract = i.Contract, 
   		@itembillgroup = i.BillGroup, @invdate = i.InvDate, @limitopt = JBLimitOpt,
   	 	@fromdate = i.FromDate, @todate = i.ToDate, @procgroup = i.ProcessGroup,
   	 	@payterms = i.PayTerms, @acothrudate = i.ACOThruDate,
		@autoinit = i.AutoInitYN, @billtype = i.BillType, @billinitopt = InitOption
	from inserted i
	join bJCCM c with (nolock) on c.JCCo = i.JBCo and c.Contract = i.Contract
	where JBCo = @jbco and BillMonth = @billmth and BillNumber = @billnum 
   
   	if @payterms is not null
   		begin
   		exec @rcode = bspHQPayTermsDateCalc @payterms, @invdate, @discdate output, @duedate output, @discrate output, @errmsg output
   		if @rcode <> 0 goto error
   		end

   	if @billtype in ('P','B') and @contract is not null	--Only initialize JBIT and Prev ChangeOrder stuff if Contract exists.          
   		begin	/* Begin BillType P or B */
   		--if @billtype <> 'P' select @autoinit = 'N'

   		exec @rcode = bspJBProgressBillItemsInit @jbco, @billmth, @contract, @itembillgroup, @invdate, @fromdate, 
       		@todate, @procgroup, @billnum, @discrate, @acothrudate, @autoinit, @billinitopt, @errmsg output
   		if @rcode <> 0 goto error
 
   		/* Begin PrevChgOrderAdds/Deds Update Process */
   		select @prevchgorderadds = 0, @prevchgorderdeds = 0, @prevchgorderamt = 0	
   
   		/* Update PrevChgOrderAdds and PrevChgOrderDeds for this new Bill.  Total up 
   		   Change Order values from earlier Bills relative to the Items on this 
   		   new Bill. */
   		declare bcPrevJBIN cursor local fast_forward for
   		select BillMonth, BillNumber
   		from bJBIN with (nolock)
   		where JBCo = @jbco and Contract = @contract 
   			and ((BillMonth < @billmth) or (BillMonth = @billmth and BillNumber < @billnum))
   			and InvStatus <> 'D'
   		order by BillMonth, BillNumber
   		
   		open bcPrevJBIN
   		select @openPrevBillcursor = 1
   		
   		fetch next from bcPrevJBIN into @prevbillmth, @prevbillnumber
   		while @@fetch_status = 0
   			begin	/* Begin Previous Bill Loop for this New Bill. */
   			declare bcPrevACO cursor local fast_forward for
   		 	select distinct(ACO)
   		 	from bJBCC with (nolock)
   		 	where JBCo = @jbco and BillMonth = @prevbillmth and BillNumber = @prevbillnumber
   			order by ACO
 		
   			open bcPrevACO
   			select @openPrevACOcursor = 1
   			
   			fetch next from bcPrevACO into @prevaco
   			while @@fetch_status = 0
   				begin	
   		 		select @prevchgorderamt = isnull(sum(ChgOrderAmt),0)
   				from bJBCX x with (nolock)	
   				join bJCOI i with (nolock) on i.JCCo = x.JBCo and i.Job = x.Job and i.ACO = x.ACO and i.ACOItem = x.ACOItem
   				-- join JBIT for current bill (NOT prev bills) to accumulate totals relative to only those Items on this bill.  
   				join bJBIT t with (nolock) on t.JBCo = @jbco and t.BillMonth = @billmth and t.BillNumber = @billnum and t.Item = i.Item
   				where x.JBCo = @jbco and x.BillMonth = @prevbillmth and x.BillNumber = @prevbillnumber and x.ACO = @prevaco
   				
   				if @prevchgorderamt > 0 select @prevchgorderadds = @prevchgorderadds + @prevchgorderamt
   				if @prevchgorderamt < 0 select @prevchgorderdeds = @prevchgorderdeds + @prevchgorderamt
   		
   				fetch next from bcPrevACO into @prevaco
   				end
   			
   			if @openPrevACOcursor = 1
   				begin
   				close bcPrevACO
   				deallocate bcPrevACO
   				select @openPrevACOcursor = 0
   				end
   		
   			fetch next from bcPrevJBIN into @prevbillmth, @prevbillnumber
   			end		/* End Previous Bill Loop for this New Bill */

   		/* We now have PrevChgOrderAdds/Deds totals relative to this New Bill. Time to Update */
   		if @openPrevBillcursor = 1
   			begin
   			close bcPrevJBIN
   			deallocate bcPrevJBIN
   			select @openPrevBillcursor = 0
   			end
 
   
   		/* This bJBIN record has been inserted at this time.  We now need to update this
   		   record with PrevChgOrderAdds/Deds values. */
		update bJBIN 
   		set PrevChgOrderAdds = @prevchgorderadds, PrevChgOrderDeds = @prevchgorderdeds, AuditYN = 'N'
        	from inserted i
   		join bJBIN j on i.JBCo = j.JBCo and i.BillMonth = j.BillMonth and i.BillNumber = j.BillNumber
        	where i.JBCo = @jbco and i.BillMonth = @billmth and i.BillNumber = @billnum
   	
		update bJBIN 
   		set AuditYN = 'Y'
        	from inserted i
   		join bJBIN j on i.JBCo = j.JBCo and i.BillMonth = j.BillMonth and i.BillNumber = j.BillNumber
        	where i.JBCo = @jbco and i.BillMonth = @billmth and i.BillNumber = @billnum
   
       	end 	/* End BillType P or B */
   
   -- 	/* read JBCO info */
   -- 	select @invopt = b.InvoiceOpt, @autoseq = b.AutoSeqInvYN, @arco = c.ARCo
   -- 	from bJBCO b
   -- 	join bJCCO c on c.JCCo = b.JBCo
   -- 	where b.JBCo = @jbco
   
   -- 	/* update JBCO with new invoice */
   --	/*   Rem'd per Issue 24031:  Redundant code!  This update has already taken place when 
   --	   bspJBGetLastInvoice ran which created the automatic Invoice input on the form to begin with.
   --     In addition to creating bill manually, I also verified that Automatically initializing
   --	   bills using both Progress Bill Init and T&M Init will also generate Invoice numbers correctly
   --	   without the following code.  I will leave it here in case something has been overlooked. */
   -- 	if @autoseq = 'Y' and isnumeric(@invoice) = 1 and @invopt='J'	
   -- 		begin
   -- 		update bJBCO
   -- 		set LastInvoice = str(@invoice,10), AuditYN = 'N'
   -- 		where JBCo = @jbco and @invoice > LastInvoice
   -- 
   -- 		update bJBCO
   -- 		set AuditYN = 'Y'
   -- 		where JBCo = @jbco
   -- 		end
   -- 
   -- 	/* update ARCO with new invoice */
   -- 	if @autoseq = 'Y' and isnumeric(@invoice)= 1 and @invopt='A'
   -- 		begin 
   -- 		update bARCO
   -- 		set InvLastNum = str(@invoice,10), AuditYN = 'N'
   -- 		where ARCo = @arco and @invoice > InvLastNum
   -- 
   -- 		update bARCO
   -- 		set AuditYN = 'Y'
   -- 		where ARCo = @arco
   -- 		end
   
   		fetch next from bcInserted into @jbco, @billmth, @billnum, @purgeyn, @audityn
   
      	end		/* End Inserted Loop */
      	
      	
begin_audit:      	
   
   /*Issue 13667 (11/16/2001)*/
   Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
   Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'A', null, null, null, getdate(), SUSER_SNAME()
   From inserted i
   Join bJBCO c with (nolock) on c.JBCo = i.JBCo
   Where c.AuditBills = 'Y' and i.AuditYN = 'Y'
   
   if @openinsertcursor = 1
   	begin
   	close bcInserted
   	deallocate bcInserted
   	select @openinsertcursor = 0
   	end
   if @openPrevBillcursor = 1
   	begin
   	close bcPrevJBIN
   	deallocate bcPrevJBIN
   	select @openPrevBillcursor = 0
   	end
   if @openPrevACOcursor = 1
   	begin
   	close bcPrevACO
   	deallocate bcPrevACO
   	select @openPrevACOcursor = 0
   	end
   
   return
   
   error:
   	select @errmsg = @errmsg + ' - cannot insert JB Progress Bill Header (JBIN)!'
   	RAISERROR(@errmsg, 11, -1);
   	rollback transaction
   	if @openinsertcursor = 1
   		begin
   		close bcInserted
   		deallocate bcInserted
   		select @openinsertcursor = 0
   		end
   	if @openPrevBillcursor = 1
   		begin
   		close bcPrevJBIN
   		deallocate bcPrevJBIN
   		select @openPrevBillcursor = 0
   		end
   	if @openPrevACOcursor = 1
   		begin
   		close bcPrevACO
   		deallocate bcPrevACO
   		select @openPrevACOcursor = 0
   		end
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  trigger [dbo].[btJBINu] on [dbo].[bJBIN] for UPDATE as

/*-----------------------------------------------------------------
* CREATED: ??
* MODIFIED: 
*		allenn 06/06/01 - include code to add HQ Master Audit entry
*		allenn 07/26/01 - edited code to add HQ Master Audit entry issue #13667
*     	kb 2/19/2 - issue #16147
*		kb 8/2/2 - issue #18143 - update Purge on JBIJ
*		TJL 11/06/02 - Issue #18740, Update Purge Flag in JBCC, JBMD, JBIT, JBIL, JBID
*		TJL 11/18/02 - Issue #17278, Allow changes to Bills in subledger closed months
*		RBT 08/05/03 - Issue #22019, Convert bDollar and bUnits to varchar(13) in auditing.
*		TJL 12/16/03 - Issue #21076, Update Previous ChgOrder Values automatically
*		TJL 03/15/04 - Issue #24051, Correct Keystring, Converted BillMonth
*		TJL 05/10/04 - Issue #24566, Correct incorrect (convert(varchar(), ____)) statements thru-out
*		TJL 05/10/04 - Issue #18944, Add HQMA Auditing for new JBIN.InvDescription field
*		TJL 07/30/04 - Issue #25260, Update ChgOrderAdds/Deds by BillGroup
*		TJL 09/15/06 - Issue #122473 (5x - 119946), Prevent JBIS trigger update to Future Bills CurrContract on Bill Purge
*		TJL 03/07/08 - Issue #127077, International Addresses
*		GG 06/16/08 - #128324 - fix Country/State validation 
*		TJL 07/14/08 - Issue #128287, JB International Sales Tax  
*		TJL 12/22/08 - Issue #129896, Add HQMA Audits for CertifiedDate, ClaimDate, and Certified fields
*		TJL 03/23/09 - Issue #128250, Allow Deleting Bills In Closed Mth
*
*/----------------------------------------------------------------
    
declare @errmsg varchar(255), @numrows int, @validcnt int, @jbco bCompany, 
	@billmth bMonth, @billnum int, @glco bCompany, @lastmthsubclsd bMonth, 
	@invstatus char(1), @invcustgroup bGroup, @invcustomer bCustomer,
	@invcontract bContract, @invchgorderamt bDollar, @openinsertcursor int,
	@rcode int, @prevupdateYN bYN, @billgroup bBillingGroup, @validcnt2 int,
	@nullcnt int
    
select @numrows = @@rowcount,  @openinsertcursor = 0, @rcode = 0
if @numrows = 0 return

set nocount on
    
/*Issue 13667 (11/16/2001)*/
If Update(JBCo)
   	Begin
   	select @errmsg = 'Cannot change JBCo'
   	GoTo error
   	End
    
If Update(BillMonth)
   	Begin
   	select @errmsg = 'Cannot change BillMonth'
   	GoTo error
   	End
    
If Update(BillNumber)
   	Begin
   	select @errmsg = 'Cannot change BillNumber'
   	GoTo error
   	end
   	
if update(BillState) or update(BillCountry)
	begin
	select @validcnt = count(1) 
	from dbo.bHQCountry c with (nolock) 
	join inserted i on i.BillCountry = c.Country
	select @nullcnt = count(1) from inserted where BillCountry is null
	if @validcnt + @nullcnt <> @numrows
		begin
		select @errmsg = 'Invalid Bill Country'
		goto error
		end
	-- validate Bill Country/State combinations
	select @validcnt = count(1) -- Country/State combos are unique
	from inserted i
	join dbo.bHQCO c (nolock) on c.HQCo = i.JBCo	-- join to get Default Country
	join dbo.bHQST s (nolock) on isnull(i.BillCountry,c.DefaultCountry) = s.Country and i.BillState = s.State
	select @nullcnt = count(1) from inserted where BillState is null
	if @validcnt + @nullcnt <> @numrows
		begin
		select @errmsg = 'Invalid Bill Country and State combination'
		goto error
		end
	end

if update(Purge)
	begin
	update bJBMD 
	set Purge = n.Purge, AuditYN = n.AuditYN	-- 'Y',  'N'
	from inserted n 
	join bJBMD m on n.JBCo = m.JBCo and n.BillMonth = m.BillMonth and n.BillNumber = m.BillNumber

	update bJBJE 
	set Purge = n.Purge, AuditYN = n.AuditYN
	from inserted n 
	join bJBJE e on n.JBCo = e.JBCo and n.BillMonth = e.BillMonth and n.BillNumber = e.BillNumber

	update bJBIS 
	set Purge = n.Purge, AuditYN = n.AuditYN 
	from inserted n 
	join bJBIS s on n.JBCo = s.JBCo and n.BillMonth = s.BillMonth and n.BillNumber = s.BillNumber

	update bJBCX 
	set Purge = n.Purge, AuditYN = n.AuditYN 
	from inserted n 
	join bJBCX x on n.JBCo = x.JBCo and n.BillMonth = x.BillMonth and n.BillNumber = x.BillNumber

	update bJBCC 
	set Purge = n.Purge, AuditYN = n.AuditYN 
	from inserted n 
	join bJBCC c on n.JBCo = c.JBCo and n.BillMonth = c.BillMonth and n.BillNumber = c.BillNumber

	update bJBIT 
	set Purge = n.Purge, AuditYN = n.AuditYN 
	from inserted n 
	join bJBIT t on n.JBCo = t.JBCo and n.BillMonth = t.BillMonth and n.BillNumber = t.BillNumber

	update bJBIL 
	set Purge = n.Purge, AuditYN = n.AuditYN 
	from inserted n 
	join bJBIL l on n.JBCo = l.JBCo and n.BillMonth = l.BillMonth and n.BillNumber = l.BillNumber

	update bJBID 
	set Purge = n.Purge, AuditYN = n.AuditYN 
	from inserted n 
	join bJBID d on n.JBCo = d.JBCo and n.BillMonth = d.BillMonth and n.BillNumber = d.BillNumber

	update bJBIJ 
	set Purge = n.Purge, AuditYN = n.AuditYN 	
	from inserted n 
	join bJBIJ j on n.JBCo = j.JBCo and n.BillMonth = j.BillMonth and n.BillNumber = j.BillNumber

	return
	end
   
declare bcInserted cursor local fast_forward for
select i.JBCo, i.BillMonth, i.BillNumber, i.InvStatus, i.CustGroup,
	i.Customer, i.Contract, i.ChgOrderAmt, i.BillGroup
from inserted i with (nolock)
order by i.JBCo, i.BillMonth, i.BillNumber
   
open bcInserted
select @openinsertcursor = 1
   
fetch next from bcInserted into @jbco, @billmth, @billnum, @invstatus, @invcustgroup, @invcustomer,
	@invcontract, @invchgorderamt, @billgroup
while @@fetch_status = 0
	begin	/* Begin inserted loop */
  	select @glco = c.GLCo, @prevupdateYN = b.PrevUpdateYN
  	from bJCCO c
	join bJBCO b on b.JBCo = c.JCCo
  	where c.JCCo = @jbco

  	select @lastmthsubclsd = LastMthSubClsd
  	from bGLCO
  	where GLCo = @glco
	if @billmth <= @lastmthsubclsd and @invstatus in ('A', 'D')
 		begin
		if @invstatus = 'A'
			begin
 			select @errmsg = 'Month is closed in subledgers. ' 
 			goto error
			end
		if @invstatus = 'D'
			begin
			exec @rcode = vspJBITCheckForRetgRel @jbco, @billmth, @billnum, @errmsg output
			if @rcode <> 0 
				begin
				select @errmsg = 'Month is closed in subledgers and ' + @errmsg
				goto error
				end
			end
 		end
   
   	if @prevupdateYN = 'Y' and (Update(ChgOrderAmt) and @invstatus <> 'D')
   		begin
   		exec @rcode = bspJBUpdatePrevChgOrderValues @jbco, @billmth, @billnum, @invcustgroup, @invcustomer,
   			@invcontract, @invchgorderamt, @billgroup, @errmsg output
   		if @rcode = 1 goto error
   		end
   
   	fetch next from bcInserted into @jbco, @billmth, @billnum, @invstatus, @invcustgroup, @invcustomer,
   		@invcontract, @invchgorderamt, @billgroup
	end	/* End inserted loop */
    
/*Issue 13667 (11/16/2001)*/
If exists(select * from inserted i join bJBCO c on i.JBCo = c.JBCo where (i.AuditYN = 'Y' and c.AuditBills = 'Y'))
    BEGIN
    If Update(Invoice)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'Invoice', d.Invoice, i.Invoice, getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where isnull(d.Invoice,'') <> isnull(i.Invoice,'')
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End

    If Update(Contract)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'Contract', d.Contract, i.Contract, getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where isnull(d.Contract,'') <> isnull(i.Contract,'')
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
    
    If Update(CustGroup)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'CustGroup', convert(varchar(3), d.CustGroup), convert(varchar(3), i.CustGroup), getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where d.CustGroup <> i.CustGroup
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
    
    If Update(Customer)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'Customer', convert(varchar(10), d.Customer), convert(varchar(10), i.Customer), getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where d.Customer <> i.Customer
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
    
    If Update(InvStatus)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'InvStatus', d.InvStatus, i.InvStatus, getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where d.InvStatus <> i.InvStatus
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
    
    If Update(Application)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'Application', convert(varchar(5), d.Application), convert(varchar(5), i.Application), getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where isnull(d.Application,-32768) <> isnull(i.Application,-32768)
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
   
    If Update(ProcessGroup)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'ProcessGroup', d.ProcessGroup, i.ProcessGroup, getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where isnull(d.ProcessGroup,'') <> isnull(i.ProcessGroup,'')
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
    
    If Update(RestrictBillGroupYN)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'RestrictBillGroupYN', d.RestrictBillGroupYN, i.RestrictBillGroupYN, getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where d.RestrictBillGroupYN <> i.RestrictBillGroupYN
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
    
    If Update(BillGroup)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'BillGroup', d.BillGroup, i.BillGroup, getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where isnull(d.BillGroup,'') <> isnull(i.BillGroup,'')
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
    
    If Update(RecType)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'RecType', convert(varchar(3), d.RecType), convert(varchar(3), i.RecType), getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where d.RecType <> i.RecType
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
    
    If Update(DueDate)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'DueDate', convert(varchar(8), d.DueDate,1), convert(varchar(8), i.DueDate,1), getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where d.DueDate <> i.DueDate
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
    
    If Update(InvDate)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'InvDate', convert(varchar(8), d.InvDate,1), convert(varchar(8), i.InvDate,1), getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where d.InvDate <> i.InvDate
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
    
    If Update(PayTerms)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'PayTerms', d.PayTerms, i.PayTerms, getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where isnull(d.PayTerms,'') <> isnull(i.PayTerms,'')
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
    
    If Update(DiscDate)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'DiscDate', convert(varchar(8), d.DiscDate,1), convert(varchar(8), i.DiscDate,1), getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where isnull(d.DiscDate,'') <> isnull(i.DiscDate,'')
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
    
    If Update(FromDate)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'FromDate', convert(varchar(8), d.FromDate,1), convert(varchar(8), i.FromDate,1), getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where isnull(d.FromDate,'') <> isnull(i.FromDate,'')
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
    
    If Update(ToDate)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'ToDate', convert(varchar(8), d.ToDate,1), convert(varchar(8), i.ToDate,1), getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where isnull(d.ToDate,'') <> isnull(i.ToDate,'')
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
    
    If Update(BillAddress)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'BillAddress', d.BillAddress, i.BillAddress, getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where isnull(d.BillAddress,'') <> isnull(i.BillAddress,'')
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
    
    If Update(BillAddress2)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'BillAddress2', d.BillAddress2, i.BillAddress2, getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where isnull(d.BillAddress2,'') <> isnull(i.BillAddress2,'')
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
    
    If Update(BillCity)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'BillCity', d.BillCity, i.BillCity, getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where isnull(d.BillCity,'') <> isnull(i.BillCity,'')
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
    
    If Update(BillState)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'BillState', d.BillState, i.BillState, getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where isnull(d.BillState,'') <> isnull(i.BillState,'')
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
    
    If Update(BillZip)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'BillZip', d.BillZip, i.BillZip, getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where isnull(d.BillZip,'') <> isnull(i.BillZip,'')
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End

    If Update(BillCountry)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'BillCountry', d.BillCountry, i.BillCountry, getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where isnull(d.BillCountry,'') <> isnull(i.BillCountry,'')
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End

    If Update(ARTrans)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'ARTrans', convert(varchar(10), d.ARTrans), convert(varchar(10), i.ARTrans), getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where isnull(d.ARTrans,-2147483648) <> isnull(i.ARTrans,-2147483648)
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
    
    If Update(InvTotal)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'InvTotal', convert(varchar(13), d.InvTotal), convert(varchar(13), i.InvTotal), getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where d.InvTotal <> i.InvTotal
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
    
    If Update(InvRetg)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'InvRetg', convert(varchar(13), d.InvRetg), convert(varchar(13), i.InvRetg), getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where d.InvRetg <> i.InvRetg
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
    
    If Update(RetgRel)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'RetgRel', convert(varchar(13), d.RetgRel), convert(varchar(13), i.RetgRel), getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where d.RetgRel <> i.RetgRel
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
    
    If Update(InvDisc)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'InvDisc', convert(varchar(13), d.InvDisc), convert(varchar(13), i.InvDisc), getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where d.InvDisc <> i.InvDisc
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
    
    If Update(TaxBasis)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'TaxBasis', convert(varchar(13), d.TaxBasis), convert(varchar(13), i.TaxBasis), getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where d.TaxBasis <> i.TaxBasis
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
    
    If Update(InvTax)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'InvTax', convert(varchar(13), d.InvTax), convert(varchar(13), i.InvTax), getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where d.InvTax <> i.InvTax
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
    
    If Update(InvDue)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'InvDue', convert(varchar(13), d.InvDue), convert(varchar(13), i.InvDue), getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where d.InvDue <> i.InvDue
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
    
    If Update(PrevAmt)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'PrevAmt', convert(varchar(13), d.PrevAmt), convert(varchar(13), i.PrevAmt), getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where d.PrevAmt <> i.PrevAmt
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
    
    If Update(PrevRetg)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'PrevRetg', convert(varchar(13), d.PrevRetg), convert(varchar(13), i.PrevRetg), getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where d.PrevRetg <> i.PrevRetg
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
    
    If Update(PrevRRel)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'PrevRRel', convert(varchar(13), d.PrevRRel), convert(varchar(13), i.PrevRRel), getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where d.PrevRRel <> i.PrevRRel
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
    
    If Update(PrevTax)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'PrevTax', convert(varchar(13), d.PrevTax), convert(varchar(13), i.PrevTax), getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where d.PrevTax <> i.PrevTax
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
    
    If Update(PrevDue)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'PrevDue', convert(varchar(13), d.PrevDue), convert(varchar(13), i.PrevDue), getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where d.PrevDue <> i.PrevDue
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
    
    If Update(ARRelRetgTran)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'ARRelRetgTran', convert(varchar(10), d.ARRelRetgTran), convert(varchar(10), i.ARRelRetgTran), getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where isnull(d.ARRelRetgTran,-2147483648) <> isnull(i.ARRelRetgTran,-2147483648)
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
    
    If Update(ARRelRetgCrTran)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'ARRelRetgCrTran', convert(varchar(10), d.ARRelRetgCrTran), convert(varchar(10), i.ARRelRetgCrTran), getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where isnull(d.ARRelRetgCrTran,-2147483648) <> isnull(i.ARRelRetgCrTran,-2147483648)
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
    
    If Update(ARGLCo)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'ARGLCo', convert(varchar(3), d.ARGLCo), convert(varchar(3), i.ARGLCo), getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where d.ARGLCo <> i.ARGLCo
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
    
    If Update(JCGLCo)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'JCGLCo', convert(varchar(3), d.JCGLCo), convert(varchar(3), i.JCGLCo), getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where d.JCGLCo <> i.JCGLCo
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
    
    If Update(CurrContract)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'CurrContract', convert(varchar(13), d.CurrContract), convert(varchar(13), i.CurrContract), getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where d.CurrContract <> i.CurrContract
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
    
    If Update(PrevWC)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'PrevWC', convert(varchar(13), d.PrevWC), convert(varchar(13), i.PrevWC), getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where d.PrevWC <> i.PrevWC
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
    
    If Update(WC)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'WC', convert(varchar(13), d.WC), convert(varchar(13), i.WC), getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where d.WC <> i.WC
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
    
    If Update(PrevSM)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'PrevSM', convert(varchar(13), d.PrevSM), convert(varchar(13), i.PrevSM), getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where d.PrevSM <> i.PrevSM
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
    
    If Update(Installed)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'Installed', convert(varchar(13), d.Installed), convert(varchar(13), i.Installed), getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where d.Installed <> i.Installed
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
    
    If Update(Purchased)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'Purchased', convert(varchar(13), d.Purchased), convert(varchar(13), i.Purchased), getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where d.Purchased <> i.Purchased
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
    
    If Update(SM)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'SM', convert(varchar(13), d.SM), convert(varchar(13), i.SM), getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where d.SM <> i.SM
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
    
    If Update(SMRetg)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'SMRetg', convert(varchar(13), d.SMRetg), convert(varchar(13), i.SMRetg), getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where d.SMRetg <> i.SMRetg
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
    
    If Update(PrevSMRetg)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'PrevSMRetg', convert(varchar(13), d.PrevSMRetg), convert(varchar(13), i.PrevSMRetg), getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where d.PrevSMRetg <> i.PrevSMRetg
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
    
    If Update(PrevWCRetg)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'PrevWCRetg', convert(varchar(13), d.PrevWCRetg), convert(varchar(13), i.PrevWCRetg), getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where d.PrevWCRetg <> i.PrevWCRetg
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
    
    If Update(WCRetg)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'WCRetg', convert(varchar(13), d.WCRetg), convert(varchar(13), i.WCRetg), getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where d.WCRetg <> i.WCRetg
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
    
    If Update(PrevChgOrderAdds)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'PrevChgOrderAdds', convert(varchar(13), d.PrevChgOrderAdds), convert(varchar(13), i.PrevChgOrderAdds), getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where d.PrevChgOrderAdds <> i.PrevChgOrderAdds
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
    
    If Update(PrevChgOrderDeds)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'PrevChgOrderDeds', convert(varchar(13), d.PrevChgOrderDeds), convert(varchar(13), i.PrevChgOrderDeds), getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where d.PrevChgOrderDeds <> i.PrevChgOrderDeds
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
    
    If Update(ChgOrderAmt)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'ChgOrderAmt', convert(varchar(13), d.ChgOrderAmt), convert(varchar(13), i.ChgOrderAmt), getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where d.ChgOrderAmt <> i.ChgOrderAmt
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
    
    If Update(BillOnCompleteYN)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'BillOnCompleteYN', d.BillOnCompleteYN, i.BillOnCompleteYN, getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where d.BillOnCompleteYN <> i.BillOnCompleteYN
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
    
    If Update(BillType)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'BillType', d.BillType, i.BillType, getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where d.BillType <> i.BillType

		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
    
    If Update(Template)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'Template', d.Template, i.Template, getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where isnull(d.Template,'') <> isnull(i.Template,'')
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
    
    If Update(CustomerReference)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'CustomerReference', d.CustomerReference, i.CustomerReference, getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where isnull(d.CustomerReference,'') <> isnull(i.CustomerReference,'')
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
    
    If Update(CustomerJob)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'CustomerJob', d.CustomerJob, i.CustomerJob, getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where isnull(d.CustomerJob,'') <> isnull(i.CustomerJob,'')
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
    
    If Update(ACOThruDate)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'ACOThruDate', convert(varchar(8), d.ACOThruDate,1), convert(varchar(8), i.ACOThruDate,1), getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where isnull(d.ACOThruDate,'') <> isnull(i.ACOThruDate,'')
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
    
    If Update(OverrideGLRevAcctYN)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'OverrideGLRevAcctYN', d.OverrideGLRevAcctYN, i.OverrideGLRevAcctYN, getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where d.OverrideGLRevAcctYN <> i.OverrideGLRevAcctYN
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
    
    If Update(OverrideGLRevAcct)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'OverrideGLRevAcct', d.OverrideGLRevAcct, i.OverrideGLRevAcct, getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where isnull(d.OverrideGLRevAcct,'') <> isnull(i.OverrideGLRevAcct,'')
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End

    If Update(InvDescription)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'InvDescription', d.InvDescription, i.InvDescription, getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where isnull(d.InvDescription,'') <> isnull(i.InvDescription,'')
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End

    If Update(RetgTax)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'RetgTax', convert(varchar(13), d.RetgTax), convert(varchar(13), i.RetgTax), getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where d.RetgTax <> i.RetgTax
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
    
    If Update(PrevRetgTax)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'PrevRetgTax', convert(varchar(13), d.PrevRetgTax), convert(varchar(13), i.PrevRetgTax), getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where d.PrevRetgTax <> i.PrevRetgTax
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End

    If Update(RetgTaxRel)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'RetgTaxRel', convert(varchar(13), d.RetgTaxRel), convert(varchar(13), i.RetgTaxRel), getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where d.RetgTaxRel <> i.RetgTaxRel
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End
    
    If Update(PrevRetgTaxRel)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'PrevRetgTaxRel', convert(varchar(13), d.PrevRetgTaxRel), convert(varchar(13), i.PrevRetgTaxRel), getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where d.PrevRetgTaxRel <> i.PrevRetgTaxRel
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End

    If Update(Certified)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'Certified', convert(varchar(1), d.Certified), convert(varchar(1), i.Certified), getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where d.Certified <> i.Certified
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End

	If Update(CertifiedDate)
		begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'CertifiedDate', convert(varchar(8), d.CertifiedDate,1), convert(varchar(8), i.CertifiedDate,1), getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where isnull(d.CertifiedDate, '') <> isnull(i.CertifiedDate, '')
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		end

    If Update(ClaimDate)
		Begin
		Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
		Select 'bJBIN', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber),i.JBCo, 'C', 'ClaimDate', convert(varchar(8), d.ClaimDate,1), convert(varchar(8), i.ClaimDate,1), getdate(), SUSER_SNAME()
		From inserted i
		Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
		Join bJBCO c on c.JBCo = i.JBCo
		Where isnull(d.ClaimDate, '') <> isnull(i.ClaimDate, '')
		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
		End

    END
   
if @openinsertcursor = 1
	begin
	close bcInserted
	deallocate bcInserted
	select @openinsertcursor = 0
	end
    
return

error:
select @errmsg = @errmsg + ' - cannot update JB Bill Header!'
RAISERROR(@errmsg, 11, -1);
rollback transaction
if @openinsertcursor = 1
	begin
	close bcInserted
	deallocate bcInserted
	select @openinsertcursor = 0
	end
   
   
   
  
 





GO
ALTER TABLE [dbo].[bJBIN] ADD CONSTRAINT [PK_bJBIN] PRIMARY KEY NONCLUSTERED  ([KeyID]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IX_bJBIN_Contract] ON [dbo].[bJBIN] ([Contract], [BillMonth], [BillNumber], [JBCo]) INCLUDE ([InvStatus]) ON [PRIMARY]
GO
CREATE UNIQUE CLUSTERED INDEX [biJBIN] ON [dbo].[bJBIN] ([JBCo], [BillMonth], [BillNumber]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biJBINInvoice] ON [dbo].[bJBIN] ([JBCo], [Invoice]) ON [PRIMARY]
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJBIN].[RestrictBillGroupYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJBIN].[AutoInitYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJBIN].[BillOnCompleteYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJBIN].[Purge]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJBIN].[AuditYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJBIN].[OverrideGLRevAcctYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJBIN].[RevRelRetgYN]'
GO
EXEC sp_bindrule N'[dbo].[brYesNo]', N'[dbo].[bJBIN].[TMUpdateAddonYN]'
GO
