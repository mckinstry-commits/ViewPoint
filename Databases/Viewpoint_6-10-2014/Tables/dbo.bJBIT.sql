CREATE TABLE [dbo].[bJBIT]
(
[JBCo] [dbo].[bCompany] NOT NULL,
[BillMonth] [dbo].[bMonth] NOT NULL,
[BillNumber] [int] NOT NULL,
[Item] [dbo].[bContractItem] NOT NULL,
[Description] [dbo].[bItemDesc] NULL,
[UnitsBilled] [dbo].[bUnits] NOT NULL,
[AmtBilled] [dbo].[bDollar] NOT NULL,
[RetgBilled] [dbo].[bDollar] NOT NULL,
[RetgRel] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJBIT_RetgRel] DEFAULT ((0.00)),
[Discount] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJBIT_Discount] DEFAULT ((0.00)),
[TaxBasis] [dbo].[bDollar] NOT NULL,
[TaxAmount] [dbo].[bDollar] NOT NULL,
[AmountDue] [dbo].[bDollar] NOT NULL,
[PrevUnits] [dbo].[bUnits] NOT NULL,
[PrevAmt] [dbo].[bDollar] NOT NULL,
[PrevRetg] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJBIT_PrevRetg] DEFAULT ((0.00)),
[PrevRetgReleased] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJBIT_PrevRetgReleased] DEFAULT ((0.00)),
[PrevTax] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJBIT_PrevTax] DEFAULT ((0.00)),
[PrevDue] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJBIT_PrevDue] DEFAULT ((0.00)),
[ARLine] [smallint] NULL,
[ARRelRetgLine] [tinyint] NULL,
[ARRelRetgCrLine] [tinyint] NULL,
[TaxGroup] [dbo].[bGroup] NULL,
[TaxCode] [dbo].[bTaxCode] NULL,
[CurrContract] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJBIT_CurrContract] DEFAULT ((0.00)),
[ContractUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bJBIT_ContractUnits] DEFAULT ((0.000)),
[PrevWC] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJBIT_PrevWC] DEFAULT ((0.00)),
[PrevWCUnits] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bJBIT_PrevWCUnits] DEFAULT ((0.000)),
[WC] [dbo].[bDollar] NOT NULL,
[WCUnits] [dbo].[bUnits] NOT NULL,
[PrevSM] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJBIT_PrevSM] DEFAULT ((0.00)),
[Installed] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJBIT_Installed] DEFAULT ((0.00)),
[Purchased] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJBIT_Purchased] DEFAULT ((0.00)),
[SM] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJBIT_SM] DEFAULT ((0.00)),
[SMRetg] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJBIT_SMRetg] DEFAULT ((0.00)),
[PrevSMRetg] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJBIT_PrevSMRetg] DEFAULT ((0.00)),
[PrevWCRetg] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJBIT_PrevWCRetg] DEFAULT ((0.00)),
[WCRetg] [dbo].[bDollar] NOT NULL,
[BillGroup] [dbo].[bBillingGroup] NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[Contract] [dbo].[bContract] NULL,
[Purge] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJBIT_Purge] DEFAULT ('N'),
[AuditYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJBIT_AuditYN] DEFAULT ('Y'),
[WCRetPct] [dbo].[bPct] NULL,
[ChangedYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJBIT_ChangedYN] DEFAULT ('N'),
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1),
[RetgTax] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJBIT_RetgTax] DEFAULT ((0.00)),
[PrevRetgTax] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJBIT_PrevRetgTax] DEFAULT ((0.00)),
[RetgTaxRel] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJBIT_RetgTaxRel] DEFAULT ((0.00)),
[PrevRetgTaxRel] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJBIT_PrevRetgTaxRel] DEFAULT ((0.00)),
[ReasonCode] [dbo].[bReasonCode] NULL,
[AmtClaimed] [dbo].[bDollar] NOT NULL CONSTRAINT [DF_bJBIT_AmtClaimed] DEFAULT ((0.00)),
[UnitsClaimed] [dbo].[bUnits] NOT NULL CONSTRAINT [DF_bJBIT_UnitsClaimed] DEFAULT ((0.00)),
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
   
CREATE TRIGGER [dbo].[btJBITd] ON [dbo].[bJBIT]
FOR DELETE AS

/****************************************************************************
* This trigger rejects delete of bJBIT (JB Item Totals)
* if the following error condition exists:
*
* none
*
* Updates corresponding fields in JBIN.
* Modified by: kb 3/29/00 - not on Version 5.1
* 		bc 04/19/00 - added update to JBIN.PrevRRel
*  		kb 2/8/01 - issue #12255
*     	kb 7/24/1 - issue #13454
*     	kb 9/26/1 - issue #14664
*    	ALLENN 11/16/2001 Issue #13667
*    	kb 2/19/2 - issue #16147
*		kb 8/5/2 - issue #18207 - changed view usage to tables
*		TJL 10/29/02 - Issue #18907, Correct LimitOpt Check and Warning Code
*		TJL 11/06/02 - Issue #18740, No need to update JBIN, JBBE, JBCX, or JBCC when bill is purged
*		TJL 01/28/03 - Issue #17278, Update Previous Amounts on Later bills.
*		TJL 09/08/03 - Issue #22126, Speed enhancement, remove psuedo cursor
*		TJL 03/15/04 - Issue #24051, Correct Keystring, Converted BillMonth
*		TJL 05/10/04 - Issue #24566, Correct incorrect (convert(varchar(), ____)) statements thru-out
*		TJL 07/18/08 - Issue #128287, JB International Sales Tax
*		TJL 12/22/08 - Issue #129896, Add JBIN updates to AmtClaimed.
*
****************************************************************************/
declare @errmsg varchar(255), @validcnt int, @errno int, @numrows int, @nullcnt int,
	@co bCompany, @billnum int, @contract bContract, @aco bACO, @item bContractItem, 
   	@invtotal bDollar, @invretg bDollar, @invrelretg bDollar, @invdisc bDollar, @taxbasis bDollar,
   	@invtax bDollar, @invdue bDollar, @currcontract bDollar, @wc bDollar, @billmth bMonth,
   	@installed bDollar, @purchased bDollar, @prevsm bDollar, @sm bDollar, @smretg bDollar, @wcretg bDollar,
   	@prevwc bDollar, @prevwcretg bDollar, @prevretgrel bDollar, @job bJob, @acoitem bContractItem,
   	@jcoi_contract bContract, @jcoi_contractitem bContractItem, @limitopt char(1), @todate bDate, 
   	@billtype char(1), @taxinterface bYN, @jbittotal bDollar, @jbintotal bDollar,  
   	@otheritem bContractItem, @otherjbittotal bDollar, @othercurrcontract bDollar,
   	@audityn bYN, @purgeyn bYN,
   	@prevupdateYN bYN, @prevunits bUnits, @prevwcunits bUnits, @prevamt bDollar, @prevretg bDollar,
   	@prevtax bDollar, @prevdue bDollar, @prevsmretg bDollar, @invunits bUnits,  @wcunits bUnits,
   	@icontract bContract, @firstmth bMonth, @firstbill int, @openbJBITcursor int, @openotheritemcursor int,
	@invamtclaimed bDollar,
   	/* JB International Sales Tax */
	@invretgtax bDollar, @invrelretgtax bDollar, @prevretgtax bDollar, @prevretgtaxrel bDollar

select @numrows = @@rowcount, @openbJBITcursor = 0, @openotheritemcursor = 0

if @numrows = 0 return
set nocount on

declare bJBIT_delete cursor local fast_forward for
select JBCo, BillMonth, BillNumber, Item, AuditYN, Purge
from deleted

open bJBIT_delete
select @openbJBITcursor = 1

fetch next from bJBIT_delete into @co, @billmth, @billnum, @item, @audityn, @purgeyn
while @@fetch_status = 0
   	/************* Get some preliminary values **************/
   	begin	/* Begin JBIT Inserted Loop */
   	select @prevupdateYN = PrevUpdateYN
   	from bJBCO with (nolock)
   	where JBCo = @co
   
	select @contract = n.Contract, @limitopt = c.JBLimitOpt, @taxinterface = c.TaxInterface,
		@todate = n.ToDate
	from bJBIN n with (nolock)
	join bJCCM c with (nolock) on c.JCCo = n.JBCo and c.Contract = n.Contract
	where n.JBCo = @co and n.BillMonth = @billmth and n.BillNumber = @billnum
   
   	/* At this moment, the revised item value is available in bJBIT.  The 
   	   sum(AmtBilled) is current including this delete. 
   	   ***** If no more Bill/Items exist, the result could be NULL ***** */
   	if @contract is not null
		begin
		select @jbintotal = isnull(sum(t.AmtBilled) + 
			case @taxinterface when 'Y' then sum(t.TaxAmount) else 0 end +
			case @taxinterface when 'Y' then sum(t.RetgTax) else 0 end, 0)
		from bJBIT t with (nolock)
   		join bJBIN n with (nolock) on n.JBCo = t.JBCo and n.BillMonth = t.BillMonth and n.BillNumber = t.BillNumber
		where t.JBCo = @co and t.Contract = @contract and n.InvStatus <> 'D'
   			and (t.BillMonth < @billmth or (t.BillMonth = @billmth and t.BillNumber <= @billnum))
   		end
   
   	select @invtotal = AmtBilled, @invretg = RetgBilled, @invretgtax = RetgTax, 
		@invrelretg = RetgRel, @invrelretgtax = RetgTaxRel,
    	@invdisc = Discount, @taxbasis = TaxBasis, @invtax = TaxAmount, @invunits = UnitsBilled,
    	@invdue = AmountDue, @currcontract = CurrContract, @wc = WC, @wcunits=WCUnits,
    	@installed = Installed, @purchased = Purchased, @sm = SM, @smretg = SMRetg,
   		@wcretg = WCRetg, @prevwc = PrevWC, @prevsm = PrevSM, @prevwcretg = PrevWCRetg, 
 		@prevamt = PrevAmt, @prevretg = PrevRetg, @prevretgtax = PrevRetgTax,
		@prevretgrel = PrevRetgReleased, @prevretgtaxrel = PrevRetgTaxRel,
		@prevtax = PrevTax, @prevdue = PrevDue, @prevsmretg = PrevSMRetg,
   		@prevunits = PrevUnits, @prevwcunits = PrevWCUnits, @icontract = Contract,
		@invamtclaimed = AmtClaimed 		         	  
   	from deleted d
   	where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Item = @item
   
   	/* If purge flag is set to 'Y', two conditions may exist.
   	1) If this is a single Bill being deleted by hitting 'Delete' Key
   	   then do only the updates to Previous Values in later bills and skip
   	   all other updates to related detail records that will be deleted
   	   anyway.
   
   	2) If this is a True Purge then multiple Bills may exist in the 
   	   'delete' queue.  Exit immediately since the 'delete' queue
   	   will contain ONLY Bills (Detail Tables will contain
   	   ONLY records) marked for PURGE.  Therefore there is no sense in
   	   cycling through each Bill because they are ALL marked to be Purged.
   	   DO NOT UPDATE PREVIOUS VALUES.
   	****NOTE**** 
   	JB is unique in that a user is allowed to delete a bill and its detail
   	from a JB Bill Header form.  There is potential for leaving detail out
   	there if a JBIN record is removed ADHOC but user insist on this capability. */
 
   	/* Bill Delete, Update Previous amounts on Later bills */
   	if @purgeyn = 'Y' and @audityn = 'Y' 
   		begin
   		goto UpdatePrev
   		end
   	/* Bill Purge, Do NOT update Previous Amounts on Later bills */
   	if @purgeyn = 'Y' and @audityn = 'N'
   		begin
   		if @openbJBITcursor = 1
   			begin
   			close bJBIT_delete
   			deallocate bJBIT_delete
   			select @openbJBITcursor = 0
   			end
   		return
   		end

   	/* If neither bill delete or bill purge, allow updates to related tables */
   
   	/* Updating bJBIN at this point with deleted values from this item can also
   	   be used later to determine Total Amount Billed for this Contract.  Once this
   	   update occurs, newly deleted values become available for evaluation. */
   	update bJBIN
   	set InvTotal = InvTotal - @invtotal, InvRetg = InvRetg - @invretg, RetgTax = RetgTax - @invretgtax,
		RetgRel = RetgRel - @invrelretg, RetgTaxRel = RetgTaxRel - @invrelretgtax, InvDisc = InvDisc - @invdisc,
		TaxBasis = TaxBasis - @taxbasis, InvTax = InvTax - @invtax,
		InvDue = InvDue - @invdue, CurrContract = CurrContract - @currcontract,
		WC = WC - @wc, Installed = Installed - @installed, Purchased = Purchased - @purchased,
		PrevSM = PrevSM - @prevsm, SM = SM - @sm, SMRetg = SMRetg - @smretg,
   		WCRetg = WCRetg - @wcretg, PrevWC = PrevWC - @prevwc,
   		PrevWCRetg = PrevWCRetg - @prevwcretg, 
   		PrevAmt = PrevAmt - @prevamt, PrevRetg = PrevRetg - @prevretg, PrevRetgTax = PrevRetgTax - @prevretgtax,
   		PrevRRel = PrevRRel - @prevretgrel, PrevRetgTaxRel = PrevRetgTaxRel - @prevretgtaxrel,
   		PrevTax = PrevTax - @prevtax, PrevDue = PrevDue - @prevdue,
   		PrevSMRetg = PrevSMRetg - @prevsmretg, 
		AmtClaimed = AmtClaimed - @invamtclaimed,
   		AuditYN = 'N'
   	from bJBIN	with (nolock)
   	where JBCo = @co and BillNumber = @billnum and BillMonth = @billmth

/* These were set to + for reasons I don't understand.  I changed them above to - since we are deleting a portion
   of the overall Prev value in JBIN and therefore reducing the total JBIN value by amount deleted. 
   CHANGED 07/22/08 as part of the JB International Tax mods.  ALL others above were already set to - */
--PrevAmt = PrevAmt + @prevamt, PrevRetg = PrevRetg + @prevretg,
--PrevTax = PrevTax + @prevtax, PrevDue = PrevDue + @prevdue, PrevSMRetg = PrevSMRetg + @prevsmretg,

   	update bJBIN 
   	set AuditYN = 'Y'
   	from bJBIN with (nolock)
   	where JBCo = @co and BillNumber = @billnum and BillMonth = @billmth
   	
   	/* Issue #18907:  As the deleted value for this Item is processed here, 
   	   JBIT already recognizes its deleted value at this time.  Just go to bJBIT 
   	   directly for the current sum(AmtBilled) for this item. (Represents the full 
   	   AmtBilled for this item up to this moment.  We will not include Bills marked for
   	   delete and evaluation is intentionally done from this bill backwards.*/				
   	/* ***** If no more Bill/Items exist, the result could be NULL ***** */
   	select @jbittotal = isnull(sum(t.AmtBilled) + 
   		case @taxinterface when 'Y' then sum(t.TaxAmount) else 0 end +
		case @taxinterface when 'Y' then sum(t.RetgTax) else 0 end, 0)
   	from bJBIT t with (nolock)
   	join bJBIN n with (nolock) on n.JBCo = t.JBCo and n.BillMonth = t.BillMonth and n.BillNumber = t.BillNumber
   	where t.JBCo = @co and t.Contract = @contract and t.Item = @item and n.InvStatus <> 'D'
   		and (t.BillMonth < @billmth or (t.BillMonth = @billmth and t.BillNumber <= @billnum))
   	
   	/* select @jbintotal =  ** Was Retrieved above after contract was established ** */
   
   	/* If limitopt = 'I', has the AmtBilled exceeded the Total Amount for this item */
   	if @limitopt = 'I'
   		begin	/* Begin LimitOpt 'I' Loop */
		select @billtype = BillType, @currcontract = ContractAmt		--Includes Change Orders
  		from bJCCI	with (nolock)
   		where JCCo = @co and Contract = @contract and Item = @item
   
		if @billtype in ('B','T')
    		begin
   			if @jbittotal > @currcontract
        		begin
        		exec bspJBTandMTransErrors @co, @billmth, @billnum, null,
        			null, 101, @errmsg output
        		end
   			else
   				begin
   				/* Unfortunately if This Item is not over limit AND if an 'OverLimit'
   				   error DOES exist for this bill, we must check all items to see if
   					   this conditions still exists since if this was the OverLimit item
   				   then we would want to remove the error in bJBBE.  Inefficient, Yes.
   				   BUT, most customers won't be doing this, and we will jump out of
   				   loop at earliest possible moment.  (Changing this would be desirable
   				   but pretty consuming for just a warning!) */
   				if exists(select 1 from bJBBE with (nolock) where JBCo = @co and BillMonth = @billmth
   						and BillNumber = @billnum and BillError = 101)
   					begin
   
   					declare bcOtherItem cursor local fast_forward for
   					select Item
   					from bJBIT with (nolock)
   					where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
						and Item <> @item					
   					
   					open bcOtherItem
   					select @openotheritemcursor = 1
   					
   					fetch next from bcOtherItem into @otheritem
   					while @@fetch_status = 0
   						begin
   						/* Get OtherItem total from bJBIT for this BillNumber or Earlier 
   						   not including those marked for delete. */
   						select @otherjbittotal = isnull(sum(t.AmtBilled) + 
   							case @taxinterface when 'Y' then sum(t.TaxAmount) else 0 end +
							case @taxinterface when 'Y' then sum(t.RetgTax) else 0 end, 0)
   		         		from bJBIT t with (nolock)
   						join bJBIN n with (nolock) on n.JBCo = t.JBCo and n.BillMonth = t.BillMonth and n.BillNumber = t.BillNumber
   		         		where t.JBCo = @co and t.Contract = @contract and t.Item = @otheritem and n.InvStatus <> 'D'
   							and (t.BillMonth < @billmth or (t.BillMonth = @billmth and t.BillNumber <= @billnum))
   							
   						/* Get OtherItem Contract Amount for comparison */
   	             		select @othercurrcontract = ContractAmt		--Includes Change Orders
   	               		from bJCCI with (nolock)
   						where JCCo = @co and Contract = @contract and Item = @otheritem
   	
   						/* Compare the two */
   						if @otherjbittotal > @othercurrcontract
   							begin
   							/* Error still valid, no deletion will occur */
   							goto CODelete
   							end
   									
   						/* An error exists.  Neither the actual Item or this OtherItem is 
   						   OverLimit so Get Next OtherItem for check. */
   						fetch next from bcOtherItem into @otheritem
   						end
   					
   					if @openotheritemcursor = 1
   						begin
   						close bcOtherItem
   						deallocate bcOtherItem
   						select @openotheritemcursor = 0
   						end
   
   					/* An error exists.  Neither the actual Item or any OtherItem is 
   					   OverLimit on this bill so go ahead and delete the error from bJBBE. */
            		delete bJBBE 
   					where JBCo = @co  and BillMonth = @billmth and BillNumber = @billnum
   						and BillError = 101
            		end	
   				end
        	end
     	end		/* End LimitOpt 'I' Loop */
   	
   	/* If limitopt = 'C', has the AmtBilled exceeded the Total Amount for this Contract */
   	if @limitopt = 'C'
		begin	/* Begin LimitOpt 'C' Loop */
		select @billtype = BillType
  		from bJBIN with (nolock)
   		where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
   
		select @currcontract = sum(ContractAmt)		--Includes Change Orders
  		from bJCCI with (nolock)
   		where JCCo = @co and Contract = @contract
   
		if @billtype in ('B','T')
    		begin
    		if @jbintotal > @currcontract
        		begin
        		exec bspJBTandMTransErrors @co, @billmth, @billnum, null,
        			null, 101, @errmsg output
        		end
			else
				begin
				if exists(select 1 from bJBBE with (nolock) where JBCo = @co and BillMonth = @billmth
					and BillNumber = @billnum and BillError = 101)
					begin
        			delete from bJBBE 
					where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
          				and BillError = 101
					end
    			end
			end
		end		/* End LimitOpt 'C' Loop */
   	
UpdatePrev:
   	/* Before retrieving the next item, if JBCO.PrevUpdateYN = 'Y' update all later bills,
   	   by deleting the value of this deleted item to all later bills Previous values.  We
   	   need only to Update the very next bill because the UPDATE trigger will update
   	   each bill thereafter. */
   	if @prevupdateYN = 'Y'
   		begin	/* Begin Update Previous */
   
   		select @firstmth = min(bJBIN.BillMonth)
   		from bJBIN with (nolock)
   		join bJBIT with (nolock) on bJBIN.JBCo = bJBIT.JBCo and bJBIN.BillMonth = bJBIT.BillMonth and bJBIN.BillNumber = bJBIT.BillNumber
   		where bJBIN.JBCo = @co and bJBIN.Contract = @icontract and bJBIN.InvStatus <> 'D'
   			and bJBIT.Item = @item 
   			and ((bJBIN.BillMonth > @billmth) or (bJBIN.BillMonth = @billmth and bJBIN.BillNumber > @billnum))
   
   		if @firstmth is not null
   			begin
   			select @firstbill = min(bJBIN.BillNumber)
   			from bJBIN with (nolock)
   			join bJBIT with (nolock) on bJBIN.JBCo = bJBIT.JBCo and bJBIN.BillMonth = bJBIT.BillMonth and bJBIN.BillNumber = bJBIT.BillNumber
   			where bJBIN.JBCo = @co and bJBIN.Contract = @icontract and bJBIN.InvStatus <> 'D'
   				and bJBIT.Item = @item 
   				and bJBIN.BillMonth = @firstmth and bJBIN.BillNumber > @billnum
   
   			if @firstbill is not null
   				begin
   				update bJBIT
   				set bJBIT.PrevUnits = bJBIT.PrevUnits - (@invunits), 
   					bJBIT.PrevAmt = bJBIT.PrevAmt - (@invtotal),
   					bJBIT.PrevRetg = bJBIT.PrevRetg - (@invretg), 
					bJBIT.PrevRetgTax = bJBIT.PrevRetgTax - (@invretgtax),
   					bJBIT.PrevRetgReleased = bJBIT.PrevRetgReleased - (@invrelretg),
					bJBIT.PrevRetgTaxRel = bJBIT.PrevRetgTaxRel - (@invrelretgtax),
   					bJBIT.PrevTax = bJBIT.PrevTax - (@invtax), 
   					bJBIT.PrevDue = bJBIT.PrevDue - (@invdue),
   					bJBIT.PrevWC = bJBIT.PrevWC - (@wc), 
   					bJBIT.PrevWCUnits = bJBIT.PrevWCUnits - (@wcunits),
   					bJBIT.PrevSM = bJBIT.PrevSM - (@sm), 
   					bJBIT.PrevSMRetg = bJBIT.PrevSMRetg - (@smretg),
   					bJBIT.PrevWCRetg = bJBIT.PrevWCRetg - (@wcretg),
   					bJBIT.AuditYN = 'N'
   				from bJBIT
   				join bJBIN with (nolock) on bJBIN.JBCo = bJBIT.JBCo and bJBIN.BillMonth = bJBIT.BillMonth and bJBIN.BillNumber = bJBIT.BillNumber
   				where bJBIT.JBCo = @co and bJBIT.Contract = @icontract and bJBIN.InvStatus <> 'D'
   					and bJBIT.Item = @item 
   					and bJBIT.BillMonth = @firstmth and bJBIT.BillNumber = @firstbill
   				if @@error <> 0
   					begin
   					select @errmsg = 'An error occured while updating Previous Amounts on later bills.'
   					goto error
   					end
   
   				update bJBIT
   				set bJBIT.AuditYN = 'Y'
   				from bJBIT	with (nolock)
   				join bJBIN with (nolock) on bJBIN.JBCo = bJBIT.JBCo and bJBIN.BillMonth = bJBIT.BillMonth and bJBIN.BillNumber = bJBIT.BillNumber
   				where bJBIT.JBCo = @co and bJBIT.Contract = @icontract and bJBIN.InvStatus <> 'D'
   					and bJBIT.Item = @item 
   					and bJBIT.BillMonth = @firstmth and bJBIT.BillNumber = @firstbill
   				end
   			end
   		end		/* End Update Previous */
   
   	if @purgeyn = 'Y' and @audityn = 'Y' goto NextItem		--Bill Delete
   
CODelete:
	/* 04/26/00 - delete change orders associated with the deleted JBIT item*/
   	select @job = min(Job)
   	from bJBCX with (nolock)
   	where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
	while @job is not null
		begin
		select @aco = min(ACO)
		from bJBCX	with (nolock)
		where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Job = @job
		while @aco is not null
  			begin
  			select @acoitem = min(ACOItem)
  			from bJBCX	with (nolock)
  			where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Job = @job and ACO = @aco
  			while @acoitem is not null
    			begin
    			select @jcoi_contract = Contract, @jcoi_contractitem = Item
				from JCOI with (nolock)
    			where JCCo = @co and Job = @job and ACO = @aco and ACOItem = @acoitem
   
    			if @@rowcount <> 0 and isnull(@jcoi_contract,'') = @contract and isnull(@jcoi_contractitem,'') = @item
      				begin
      				update bJBCX 
					set AuditYN = 'N' 
					where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum 
						and Job = @job and ACO = @aco and ACOItem = @acoitem
   
      				delete bJBCX
      				where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
            			and Job = @job and ACO = @aco and ACOItem = @acoitem
   
      				if not exists(select 1 from bJBCX with (nolock) where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Job = @job and ACO = @aco)
        				begin
        				update bJBCC 
						set AuditYN = 'N'
          				where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
          					and Job = @job and ACO = @aco

        				delete bJBCC
        				where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Job = @job and ACO = @aco
        				end
      				end
   
    			select @acoitem = min(ACOItem)
    			from bJBCX	with (nolock)
    			where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
          			and Job = @job and ACO = @aco and ACOItem > @acoitem
    			end
   
  			select @aco = min(ACO)
  			from bJBCX with (nolock)
  			where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Job = @job and ACO > @aco
  			end
   
		select @job = min(Job)
		from bJBCX with (nolock)
		where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Job > @job
		end
   
NextItem:
   	fetch next from bJBIT_delete into @co, @billmth, @billnum, @item, @audityn, @purgeyn
   	end		/* End JBIT Inserted Loop */
   
if @openbJBITcursor = 1
   	begin
   	close bJBIT_delete
   	deallocate bJBIT_delete
   	select @openbJBITcursor = 0
   	end
   
--------------------------------  REM'D FOR ISSUE #22126 ----------------------------------------------
/*
select @co = min(JBCo)
from deleted d
while @co is not null
   	begin
   	select @prevupdateYN = PrevUpdateYN
   	from bJBCO
   	where JBCo = @co
   
 	select @billmth = min(BillMonth)
	from deleted d
 	where JBCo = @co
  	while @billmth is not null
  		begin
      	select @billnum = min(BillNumber)
      	from deleted d
      	where JBCo = @co and BillMonth = @billmth
      	while @billnum is not null
        	begin
        	select @contract = n.Contract, @limitopt = c.JBLimitOpt, @taxinterface = c.TaxInterface,
         		@todate = n.ToDate
   			from bJBIN n
          	join bJCCM c on c.JCCo = n.JBCo and c.Contract = n.Contract
          	where n.JBCo = @co and n.BillMonth = @billmth and n.BillNumber = @billnum

   			if @contract is not null
   				begin
        		select @jbintotal = isnull(sum(t.AmtBilled) + 
					case @taxinterface when 'Y' then sum(t.TaxAmount) else 0 end +
					case @taxinterface when 'Y' then sum(t.RetgTax) else 0 end, 0)
        		from bJBIT t
   				join bJBIN n on n.JBCo = t.JBCo and n.BillMonth = t.BillMonth and n.BillNumber = t.BillNumber
				where t.JBCo = @co and t.Contract = @contract and n.InvStatus <> 'D'
   					and (t.BillMonth < @billmth or (t.BillMonth = @billmth and t.BillNumber <= @billnum))
   				end
 ----------------------------------
           	select @otheritem = min(Item) 
			from bJBIT 
			where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
             	and Item <> @item
        	while @otheritem is not null
            	begin	
   
				select @otheritem = min(Item) 
				from bJBIT 
				where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
                	and Item <> @item and Item > @otheritem
				end
----------------------------------
        	select @item = min(Item)
        	from deleted d
        	where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
        	while @item is not null
          		begin
				select @audityn = AuditYN, @purgeyn = Purge 
   				from deleted d 
   				where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Item = @item
              
   			NextItem: 
   	       		select @item = min(Item)
   	           	from deleted d
   	           	where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Item > @item 
   	           	end
   
   	    	select @billnum = min(BillNumber)
   	     	from deleted d
   	     	where JBCo = @co and BillMonth = @billmth and BillNumber > @billnum
   	      	end
   
   		select @billmth = min(BillMonth)
   		from deleted d
   	  	where JBCo = @co and BillMonth > @billmth
   	 	end
   
   	select @co = min(JBCo)
   	from deleted d
   	where JBCo > @co
   	if @@rowcount = 0 select @co = null
   	end
*/
--------------------------------  REM'D FOR ISSUE #22126 ----------------------------------------------
   
delete bJBIS
from bJBIS s
join deleted d on s.JBCo = d.JBCo and s.BillMonth = d.BillMonth and s.BillNumber = d.BillNumber
	and s.Item = d.Item 
where s.ACO = '' and s.ACOItem = '' and s.Job = ''
   
if @purgeyn = 'Y' and @audityn = 'Y' return		-- Skip Auditing for Single Bill Delete

/*Issue 13667*/
Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue,
	[DateTime], UserName)
Select 'bJBIT',
	'JBCo: ' + convert(varchar(3),d.JBCo) + 'BillMonth: ' + convert(varchar(8), d.BillMonth,1)
	+ 'BillNumber: ' + convert(varchar(10),d.BillNumber)
	+ 'Item: ' + d.Item,
	d.JBCo, 'D', null, null, null, getdate(), SUSER_SNAME()
From deleted d
Join bJBCO c on c.JBCo = d.JBCo
Where c.AuditBills = 'Y' and d.AuditYN = 'Y'
   
return

error:
select @errmsg = @errmsg + ' - cannot delete JB Invoice Item Totals!'

if @openotheritemcursor = 1
   	begin
   	close bcOtherItem
   	deallocate bcOtherItem
   	select @openotheritemcursor = 0
   	end
   
if @openbJBITcursor = 1
   	begin
   	close bJBIT_delete
   	deallocate bJBIT_delete
   	select @openbJBITcursor = 0
   	end
   
RAISERROR(@errmsg, 11, -1);
rollback transaction
   
   
  
 






GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[btJBITi] ON [dbo].[bJBIT]
FOR INSERT AS
   
/**************************************************************
*	This trigger rejects insert of bJBIT (JC Cost Detail)
*	 if the following error condition exists:
*		none
*
*	Updates corresponding fields in JBCC.
*
*  	Modified by: kb 1/27/00
*  		bc 09/19/00
*    	bc 12/4/00  - add record(s) into ARTL when a new item is inserted on a bill that has already been interfaced
*    	bc 12/15/00 if JBIN.BillType is 'T' and an item of JCCI.BillType = 'B' is added to the bill, change JBIN.BillType = 'B'
*     	bc 01/07/00 - removed join on bJBIN in JBIS insert statement since JBIT now has a Contract column
*    	bc 01/07/00 - surrounded the JBIS insert statement with an 'if not exists'
*                  	  to prevent duplicate row, run time errir
*     	kb 7/24/1 - issue #13454
*     	kb 9/26/1 - issue #14664
*     	kb 9/26/1 - issue #14680
*     	ALLENN 11/16/2001 Issue #13667
*      	kb 2/19/2 - issue #16147
*		kb 8/5/2 - issue #18207 - changed view usage to tables
*		TJL 10/24/02 - Issue #18907, Correct LimitOpt Check and Warning Code
*		TJL 01/28/03 - Issue #17278, Update Previous Amounts on Later bills.
*		TJL 09/08/03 - Issue #22126, Speed enhancement, remove psuedo cursor
*		TJL 01/19/04 - Issue #23533, Change variable @arline to smallint
*		TJL 03/15/04 - Issue #24051, Correct Keystring, Converted BillMonth
*		TJL 04/27/04 - Issue #24448, Selecting @jbintotal & @jbittotal done only when required.
*		TJL 05/10/04 - Issue #24566, Correct incorrect (convert(varchar(), ____)) statements thru-out
*		TJL 08/02/04 - Issue #25283, Correct 0.00 value ARTL line input for Orig and Adjust transactions
*		TJL 04/28/05 - Issue #28559, Limit Description on Insert into bARTL to avoid error.
*		TJL 07/18/08 - Issue #128287, JB International Sales Tax
*		TJL 12/22/08 - Issue #129896, Add JBIN updates to AmtClaimed.
*		TJL 08/26/09 - Issue #133896, JBIS Description should be kept the same for Bill Item as well as associated Bill Item ACO's
*		CHS 12/16/2011 - B-08120 - Move bills to next month
*
************************************************************************************/
declare @errmsg varchar(255), @numrows int, @co bCompany, @billnum int, @item bContractItem, 
	@arco bCompany, @artrans bTrans, @adjust_mth bMonth, @adjust_trans bTrans, @arline smallint,
   	@invtotal bDollar, @invretg bDollar, @invrelretg bDollar, @invdisc bDollar, @taxbasis bDollar,
   	@invtax bDollar, @invdue bDollar, @currcontract bDollar, @wc bDollar, @wcunits bUnits,
   	@installed bDollar, @purchased bDollar, @sm bDollar, @smretg bDollar, @wcretg bDollar,
   	@prevwc bDollar, @prevsm bDollar, @billmth bMonth, @prevwcretg bDollar, @prevamt bDollar,
   	@prevretg bDollar, @prevretgrel bDollar, @prevtax bDollar, @prevdue bDollar, @prevsmretg bDollar,
   	@limitopt char(1), @billtype char(1), @contract bContract, @taxinterface bYN,
   	@jbittotal bDollar, @jbintotal bDollar, @jcci_billtype char(1), @todate bDate, 
   	@otherjbittotal bDollar, @otheritem bContractItem, @othercurrcontract bDollar,
   	@prevupdateYN bYN, @prevunits bUnits, @prevwcunits bUnits, @invunits bUnits,
   	@firstmth bMonth, @firstbill int, @openbJBITcursor int, @openotheritemcursor int,
   	@Aarline smallint, @invamtclaimed bDollar,
	/* JB International Sales Tax */
	@invretgtax bDollar, @invrelretgtax bDollar, @prevretgtax bDollar, @prevretgtaxrel bDollar,
	@purgeyn bYN, @audityn bYN
   
declare @rcode int, @validcnt int, @nullcnt int, @jbisacocount int
select @numrows = @@rowcount, @openbJBITcursor = 0, @openotheritemcursor = 0
   
if @numrows = 0 return
set nocount on


--/* Bill Purge, Do NOT update Previous Amounts on Later bills */
--if inserted.Purge = 'Y' and inserted.AuditYN = 'Y'
--	begin
--	goto begin_audit
--	end


-- Validate ReasonCode
select @validcnt = count(*)from inserted i
JOIN bHQRC r with (nolock) ON i.ReasonCode = r.ReasonCode
select @nullcnt = count(*) from  inserted i where i.ReasonCode is null
if @validcnt + @nullcnt <> @numrows
	begin
	select @errmsg = 'Reason Code is Invalid '
	goto error
	end
   
declare bJBIT_insert cursor local fast_forward for
select JBCo, BillMonth, BillNumber, Item, Purge, AuditYN
from inserted
   
open bJBIT_insert
select @openbJBITcursor = 1

fetch next from bJBIT_insert into @co, @billmth, @billnum, @item, @purgeyn, @audityn
while @@fetch_status = 0
   	begin	/* Begin JBIT Inserted Loop */
   	select @jbisacocount = 0
   	
/* Bill Purge, Do NOT update Previous Amounts on Later bills */
if @purgeyn = 'Y' and @audityn = 'Y'
   		begin
   		if @openbJBITcursor = 1
   			begin
   			close bJBIT_insert
   			deallocate bJBIT_insert
   			select @openbJBITcursor = 0
   			end
   		goto begin_audit
   		end	
   	
   	
   	/************* Get some preliminary values **************/
   	/* Get PrevUpdateYN flag from JBCO.  It will be used later to determine if Previous Amount
   	   values need to be updated in later bills. */
   	select @prevupdateYN = b.PrevUpdateYN, @arco = c.ARCo
   	from bJBCO b with (nolock)
   	join bJCCO c with (nolock) on c.JCCo = b.JBCo
   	where b.JBCo = @co
   	if @arco is null
   		begin
   		select @arco = @co
   		end
   
   	select @contract = n.Contract, @limitopt = c.JBLimitOpt, @artrans = n.ARTrans,
		@taxinterface = c.TaxInterface, @todate = n.ToDate
   	from bJBIN n with (nolock)
   	join bJCCM c with (nolock) on c.JCCo = n.JBCo and c.Contract = n.Contract
   	where n.JBCo = @co and n.BillMonth = @billmth and n.BillNumber = @billnum
   
   	/* Need to create old values in ARTL for items that have been added after the bill had last been interfaced.
   		1) First a record needs to be inserted into the original 'I'nvoice transaction that was created by JB
   		2) If an adjustment has since been made via JB then an additional line must be added to the most recent 
          	   adjustment for that bill */
   
   	/* If Bill has previously been interfaced. */
   	if @artrans is not null
   		begin	/* Begin of adding a new record into ARTL to represent a new item added to an interfaced bill */
   		/* Look at Original 'I'nvoice transaction.  Add Item if it does not already exist. */
		if not exists(select 1 from bARTL with (nolock) where ARCo = @arco and Mth = @billmth and ARTrans = @artrans and
    		JCCo = @co and Contract = @contract and Item = @item)
   			begin	/* Begin Adding Item to original Invoice record in ARTL */
   			/* If not on Original 'I'nvoice Transaction, then the next ARLine number may come
   			   from the next ARLine number sequencially relative to JBIT. */
   			select @arline = isnull(max(ARLine),0) + 1
   			from bJBIT with (nolock)
   			where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
   
   			/* Typically ApplyLine and ARLine on the original transaction are the same.
   			   If we generate an ARLine that is already in use on the original transaction 
   			   then increment it by one and check again.  */
   		CheckNextARLine:
   			if exists(select 1 from bARTL with (nolock) where ARCo = @arco and Mth = @billmth
   					and ARTrans = @artrans and ARLine = @arline)
   				begin
   				select @arline = @arline + 1
   				goto CheckNextARLine
   				end
   	
   			/* Insert a line into the original invoice */
   			insert into bARTL (ARCo, Mth, ARTrans, ARLine, RecType, LineType,
   				Description,
   				GLCo, GLAcct, TaxGroup, TaxCode, TaxBasis, TaxAmount,
   				UM, Amount, RetgPct, Retainage, RetgTax, DiscOffered, MatlUnits, ContractUnits,
   				JCCo, Contract, Item, ApplyMth, ApplyTrans, ApplyLine)
   			select @arco, t.BillMonth, @artrans, @arline, n.RecType, 'C',
   				case n.BillType when 'T' then 'JB T&M' else 'App# ' + convert(varchar(5),n.Application) + ' ' + isnull(substring(t.Description,1,19),'') end,
   				n.JCGLCo, case m.ContractStatus when 3 then d.ClosedRevAcct else d.OpenRevAcct end,
   				t.TaxGroup, t.TaxCode, 0, 0,
   				i.UM, 0, 0, 0, 0, 0, 0, 0,
   				@co, @contract, @item, @billmth, @artrans, @arline
   			from inserted t
   			join bJBIN n with (nolock) on t.JBCo = n.JBCo and t.BillNumber = n.BillNumber and t.BillMonth = n.BillMonth
   			join bJCCI i with (nolock) on n.JBCo = i.JCCo and n.Contract = i.Contract and t.Item = i.Item
   			join bJCCM m with (nolock) on n.JBCo = m.JCCo and n.Contract = m.Contract
   			join bJCDM d with (nolock) on n.JBCo = d.JCCo and i.Department = d.Department and n.JCGLCo = d.GLCo
   			where t.JBCo = @co and t.BillMonth = @billmth and t.BillNumber = @billnum and t.Item = @item
    		
   	 		update bJBIT
   	 		set ARLine = @arline, AuditYN = 'N'
   	 		where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Item = @item
   		
   	 		update bJBIT
   	 		set AuditYN = 'Y'
   	 		where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Item = @item
   
   			end		/* End Adding Item to original Invoice record in ARTL */
   	
		/* Insert a line into the most recent adjustment, applied to the original invoice, if one exists */
		select @adjust_trans = null
   
   		/* Get Adjustment Latest Month and Latest Transaction for that Month. */
		select @adjust_mth = max(Mth)
		from bARTH with (nolock) 
		where ARCo = @arco and AppliedMth = @billmth and AppliedTrans = @artrans and ARTransType = 'A' and Source = 'JB'
   		if @adjust_mth is not null
   			begin			
  			select @adjust_trans = max(ARTrans)
			from bARTH with (nolock) 
			where ARCo = @arco and AppliedMth = @billmth and AppliedTrans = @artrans and ARTransType = 'A' and Source = 'JB'
				and Mth = @adjust_mth
   			end
   
		/* If we have a Max Adjustment transaction, check for the existence of this Item. If missing, insert. */
		if @adjust_trans is not null
       		begin	/* Begin Adding Item to latest Adjustment record in ARTL */
			/* Look at Latest Adjustment transaction.  Add Item if it does not already exist. */
 			if not exists(select 1 from bARTL with (nolock) where ARCo = @arco and Mth = @adjust_mth and ARTrans = @adjust_trans and
 				JCCo = @co and Contract = @contract and Item = @item)
				begin
   				/* @arline already exists IF the Original Invoice Transaction (for this item) got added above.
   				   @arline is null IF the Original Invoice Transaction already existed, in which case, we
   				   need to retrieve the value from the Original Invoice Transaction to assure that the ApplyLine
   				   value is correct.  (Do not want an Adjustment line applied to the wrong original line!) */
   				if @arline is null
   					begin
   					select @arline = ARLine
   					from bARTL with (nolock)
   					where ARCo = @arco and Mth = @billmth and ARTrans = @artrans
   						and JCCo = @co and Contract = @contract and Item = @item
   					if @arline is null
   						begin
   						select @errmsg = 'Old Adjustment Transaction for this Item could not be added'
   						goto error
   						end
   
   					/* Typically ApplyLine and ARLine on an Adjustment transaction are the same.
   					   However, if we encounter an Adjustment transaction where this isn't the case
   					   then our new ARLine may already be in use, if so increment it by one and check
   					   again.  ApplyLine will remain the same.  (I don't know if this condition will occur. */
   					if exists(select 1 from bARTL with (nolock) where ARCo = @arco and Mth = @adjust_mth
   							and ARTrans = @adjust_trans and ARLine = @arline)
   						begin
   						select @errmsg = 'Original and Adjustment ARLine numbers are out of sync in AR. Contact Bidtek!'
   						goto error
   						end
   					end
   			
   	   			insert into bARTL (ARCo, Mth, ARTrans, ARLine, RecType, LineType,
   	            	Description,
   	              	GLCo, GLAcct, TaxGroup, TaxCode, TaxBasis, TaxAmount,
   	              	UM, Amount, RetgPct, Retainage, RetgTax, DiscOffered, MatlUnits, ContractUnits,
   	              	JCCo, Contract, Item, ApplyMth, ApplyTrans, ApplyLine)
   	   			select @arco, @adjust_mth, @adjust_trans, @arline, n.RecType, 'C',
   	          		case n.BillType when 'T' then 'JB T&M' else 'App# ' + convert(varchar(5),n.Application) + ' ' + isnull(substring(t.Description,1,19),'') end,
   	          		n.JCGLCo, case m.ContractStatus when 3 then d.ClosedRevAcct else d.OpenRevAcct end,
   	          		t.TaxGroup, t.TaxCode, 0, 0,
   	          		i.UM, 0, 0, 0, 0, 0, 0, 0,
   	          		@co, @contract, @item, @billmth, @artrans, @arline
   	   			from inserted t
   	   			join bJBIN n with (nolock) on t.JBCo = n.JBCo  and t.BillMonth = n.BillMonth and t.BillNumber = n.BillNumber
   	   			join bJCCI i with (nolock) on n.JBCo = i.JCCo and n.Contract = i.Contract and t.Item = i.Item
   	   			join bJCCM m with (nolock) on n.JBCo = m.JCCo and n.Contract = m.Contract
   	   			join bJCDM d with (nolock) on n.JBCo = d.JCCo and i.Department = d.Department and n.JCGLCo = d.GLCo
   	   			where t.JBCo = @co and t.BillMonth = @billmth and t.BillNumber = @billnum and t.Item = @item
   
   		 		update bJBIT
   		 		set ARLine = @arline, AuditYN = 'N'
   		 		where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Item = @item
   			
   		 		update bJBIT
   		 		set AuditYN = 'Y'
   		 		where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Item = @item
   
	   			end
	 		end 	/* End Adding Item to latest Adjustment record in ARTL */
		end		/* End of adding a new record into ARTL to represent a new item added to an interfaced bill */
   
   	select @jcci_billtype = BillType
   	from bJCCI with (nolock)
   	where JCCo = @co and Contract = @contract and Item = @item
   	if @jcci_billtype not in ('P', 'T', 'B', 'N')
   		begin
   		select @errmsg = 'BillType must be set to (P), (T), (B), or (N) on this Item'
   		goto error
   		end
   
   	select @invtotal = AmtBilled, @invretg = RetgBilled, @invretgtax = RetgTax, @invrelretg = RetgRel, @invrelretgtax = RetgTaxRel,
       	@invdisc = Discount, @taxbasis = TaxBasis, @invtax = TaxAmount, @invunits = UnitsBilled,
       	@invdue = AmountDue, @currcontract = CurrContract, @wc = WC, @wcunits=WCUnits,
       	@installed = Installed, @purchased = Purchased, @sm = SM, @smretg = SMRetg,
       	@wcretg = WCRetg, @prevwc = PrevWC, @prevsm = PrevSM, @prevwcretg = PrevWCRetg,
   		@prevamt = PrevAmt , @prevretg = PrevRetg, @prevretgtax = PrevRetgTax, @prevretgrel = PrevRetgReleased, @prevretgtaxrel = PrevRetgTaxRel,
		@prevtax = PrevTax , @prevdue = PrevDue , @prevsmretg = PrevSMRetg,
   		@prevunits = PrevUnits, @prevwcunits = PrevWCUnits, @invamtclaimed = AmtClaimed
   	from inserted i
   	where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Item = @item
   
   	/* Updating bJBIN at this point with inserted values from this item can also
   	   be used later to determine Total AmountBill for this Contract.  Once this
   	   update occurs, newly inserted values become available for evaluation. */
   	update bJBIN
   	set AuditYN = 'N',
   		InvStatus = case InvStatus when 'I' then 'C' else InvStatus end,
   		InvTotal = InvTotal + @invtotal, InvRetg = InvRetg + @invretg, RetgTax = RetgTax + @invretgtax,
		RetgRel = RetgRel + @invrelretg, RetgTaxRel = RetgTaxRel + @invrelretgtax, InvDisc = InvDisc + @invdisc,
		TaxBasis = TaxBasis + @taxbasis, InvTax = InvTax + @invtax,
		InvDue = InvDue + @invdue, CurrContract = CurrContract + @currcontract,
		WC = WC + @wc, Installed = Installed + @installed, Purchased = Purchased + @purchased,
		SM = SM + @sm, SMRetg = SMRetg + @smretg, WCRetg = WCRetg + @wcretg,
   		PrevWC = PrevWC + @prevwc, PrevSM = PrevSM + @prevsm ,
   		PrevWCRetg = PrevWCRetg + @prevwcretg,
   		PrevAmt = PrevAmt + @prevamt, PrevRetg = PrevRetg + @prevretg, PrevRetgTax = PrevRetgTax + @prevretgtax,
   		PrevRRel = PrevRRel + @prevretgrel, PrevRetgTaxRel = PrevRetgTaxRel + @prevretgtaxrel,
   		PrevTax = PrevTax + @prevtax, PrevDue = PrevDue + @prevdue,
   		PrevSMRetg = PrevSMRetg + @prevsmretg,
   		BillType = case BillType when 'T' then case @jcci_billtype when 'B' then 'B' else BillType end else BillType end,
		AmtClaimed = AmtClaimed + @invamtclaimed
   	from bJBIN	with (nolock)
   	where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
   
   	if @@rowcount = 0
   		begin
   		select @errmsg = 'Error updating JBIN'
   		goto error
   		end
   
   	update bJBIN
   	set AuditYN = 'Y'
   	from bJBIN with (nolock)
   	where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
 
   	if not exists(select 1
		from bJBIS with (nolock)
		where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Item = @item and
			Job = '' and ACO = '' and ACOItem = '')
   		begin
   		insert bJBIS (JBCo, BillMonth, BillNumber, Job, Item, ACO, ACOItem, Description,
			UnitsBilled, AmtBilled, RetgBilled, RetgTax, RetgRel, RetgTaxRel, Discount, TaxBasis, TaxAmount,
			AmountDue, PrevUnits, PrevAmt, PrevRetg, PrevRetgTax, PrevRetgReleased, PrevRetgTaxRel, PrevTax, PrevDue,
			ARLine, ARRelRetgLine, ARRelRetgCrLine,
			TaxGroup, TaxCode, CurrContract, ContractUnits,
			PrevWC, PrevWCUnits, WC, WCUnits, PrevSM,
			Installed, Purchased, SM, SMRetg,
			PrevSMRetg, PrevWCRetg, WCRetg, WCRetPct,
   	       	BillGroup, Contract, ChgOrderUnits, ChgOrderAmt)
   		select JBCo, BillMonth, BillNumber,'',Item, '', '', Description,
   	 		UnitsBilled, AmtBilled, RetgBilled, RetgTax, RetgRel, RetgTaxRel, Discount, TaxBasis, TaxAmount,
   	 		AmountDue, PrevUnits, PrevAmt, PrevRetg, PrevRetgTax, PrevRetgReleased, PrevRetgTaxRel, PrevTax, PrevDue,
   	 		ARLine, ARRelRetgLine, ARRelRetgCrLine,
   	 		TaxGroup, TaxCode, CurrContract, ContractUnits,
   	 		PrevWC, PrevWCUnits, WC, WCUnits, PrevSM,
   	 		Installed, Purchased, SM, SMRetg,
   	 		PrevSMRetg, PrevWCRetg, WCRetg, WCRetPct, BillGroup, Contract, 0, 0
   		from inserted
   		where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Item = @item
   
		if @@rowcount = 0
       		begin
       		select @errmsg = 'Error updating JBIS'
       		goto error
       		end
       	
       	/* When a JBIT record gets inserted, it is possible that Change Orders have already been initialized onto the billing.
       	   Generally the JBIS Item description for the Change Orders will have been initialized by the JBCX insert trigger
       	   using the same value as we have here.  Just in case they are different for some unforseen reason, we will update
       	   the ACO's decriptions, at this time, to keep them in sync with the JBIT item description. */
       	select @jbisacocount = count(1)
		from bJBIS with (nolock)
		where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Item = @item and
			isnull(Job, '') <> '' and isnull(ACO, '') <> '' and isnull(ACOItem, '') <> ''
		if @jbisacocount <> 0
			begin
			update s
			set Description = t.Description
			from bJBIS s with (nolock)
			join inserted t on t.JBCo = s.JBCo and t.BillMonth = s.BillMonth and t.BillNumber = s.BillNumber and t.Item = s.Item
			where s.JBCo = @co and s.BillMonth = @billmth and s.BillNumber = @billnum and s.Item = @item and
				isnull(s.Job, '') <> '' and isnull(s.ACO, '') <> '' and isnull(s.ACOItem, '') <> ''
			
			if @@rowcount <> @jbisacocount
				begin
       			select @errmsg = 'Error updating JBIS ACO description.'
       			goto error
       			end
			end
   		end
   
   	/* If limitopt = 'I', has the AmtBilled exceeded the Total Amount for this item */
   	if @limitopt = 'I'
		begin	/* Begin LimitOpt 'I' Loop */
		select @currcontract = ContractAmt		--Includes Change Orders
  		from bJCCI with (nolock)
   		where JCCo = @co and Contract = @contract and Item = @item
		if @jcci_billtype in ('B','T')
			begin
   			/* Issue #18907:  As the additional value for this Item is processed here, 
   			   JBIT already contains its additional value at this time.  Just go to bJBIT 
   			   directly for the current sum(AmtBilled) for this item. (Represents the full 
   			   AmtBilled for this item up to this moment.  We will not include Bills marked for
   			   delete and evaluation is intentionally done from this bill backwards. 
   
   			   We Get Item Total only when LimitOpt is set for Item and only for Items marked
   			   as "B" or "T" (Not Progress).  This helps reduce Initialization time when
   			   the value is not to be used. */
   			select @jbittotal = sum(t.AmtBilled) + 
   				case @taxinterface when 'Y' then sum(t.TaxAmount) else 0 end +
				case @taxinterface when 'Y' then sum(t.RetgTax) else 0 end
   			from bJBIT t with (nolock)
   			join bJBIN n with (nolock) on n.JBCo = t.JBCo and n.BillMonth = t.BillMonth and n.BillNumber = t.BillNumber
   			where t.JBCo = @co and t.Contract = @contract and t.Item = @item and n.InvStatus <> 'D'
   				and (t.BillMonth < @billmth or (t.BillMonth = @billmth and t.BillNumber <= @billnum))
   
    		if @jbittotal > @currcontract
        		begin
        		exec bspJBTandMTransErrors @co, @billmth, @billnum, null,
        			null, 101, @errmsg output
        		end
    		else
            	begin
   				/* Unfortunately if This Item is not over limit AND if an 'OverLimit'
   				   error DOES exist for this bill, we must check all items to see if
   				   this conditions still exists since if this was the OverLimit item
   				   then we would want to remove the error in bJBBE.  Inefficient, Yes.
   				   BUT, most customers won't be doing this, and we will jump out of
   				   loop at earliest possible moment.  (Changing this would be desirable
   				   but pretty consuming for just a warning!) */
   				if exists(select 1 from bJBBE with (nolock) where JBCo = @co and BillMonth = @billmth
   							and BillNumber = @billnum and BillError = 101)
   					begin
      				declare bcOtherItem cursor local fast_forward for
   					select Item
   					from bJBIT with (nolock)
   					where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
                        	and Item <> @item					
   					
   					open bcOtherItem
   					select @openotheritemcursor = 1
   					
   					fetch next from bcOtherItem into @otheritem
   					while @@fetch_status = 0
   						begin
   						/* Get OtherItem total from bJBIT for this BillNumber or Earlier 
   						   not including those marked for delete. */
   						select @otherjbittotal = sum(t.AmtBilled) + 
   							case @taxinterface when 'Y' then sum(t.TaxAmount) else 0 end +
							case @taxinterface when 'Y' then sum(t.RetgTax) else 0 end
   		         		from bJBIT t with (nolock)
   						join bJBIN n with (nolock) on n.JBCo = t.JBCo and n.BillMonth = t.BillMonth and n.BillNumber = t.BillNumber
   		         		where t.JBCo = @co and t.Contract = @contract and t.Item = @otheritem and n.InvStatus <> 'D'
   							and (t.BillMonth < @billmth or (t.BillMonth = @billmth and t.BillNumber <= @billnum))
   				
   						/* Get OtherItem Contract Amount for comparison */
   	             		select @othercurrcontract = ContractAmt		--Includes Change Orders
   	               		from bJCCI with (nolock)
   						where JCCo = @co and Contract = @contract and Item = @otheritem
   
   						/* Compare the two */
   						if @otherjbittotal > @othercurrcontract
   							begin
   							/* Error still valid, no deletion will occur */
   							goto NextItem
   							end
   									
   						/* An error exists.  Neither the actual Item or this OtherItem is 
   						   OverLimit so Get Next OtherItem for check. */
   						fetch next from bcOtherItem into @otheritem
   						end
   
   					if @openotheritemcursor = 1
   						begin
   						close bcOtherItem
   						deallocate bcOtherItem
   						select @openotheritemcursor = 0
   						end
   
   					/* An error exists.  Neither the actual Item or any OtherItem is 
   					   OverLimit on this bill so go ahead and delete the error from bJBBE. */
            		delete bJBBE 
   					where JBCo = @co  and BillMonth = @billmth and BillNumber = @billnum
   						and BillError = 101
                   	end
				end
			end
   		end		/* End LimitOpt 'I' Loop */
   
   	/* If limitopt = 'C', has the AmtBilled exceeded the Total Amount for this Contract */
   	if @limitopt = 'C'	
       	begin	/* Begin LimitOpt 'C' Loop */
		select @billtype = BillType
  		from bJBIN with (nolock)
   		where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
   
		select @currcontract = sum(ContractAmt)		--Includes Change Orders
  		from bJCCI with (nolock)
   		where JCCo = @co and Contract = @contract
   
		if @billtype in ('B','T')
    		begin
   			/* At this moment, the revised item value is available in bJBIT.  The 
   			   sum(AmtBilled) is current including this insert. 
   
   			   We Get combined Item Totals only when LimitOpt is set for Contract and only for
   			   BillTypes "B" or "T" (Not Progress).  This helps reduce Initialization time when
   			   the value is not to be used.*/
   			if @contract is not null
   				begin
   		   		select @jbintotal = sum(t.AmtBilled) + 
   					case @taxinterface when 'Y' then sum(t.TaxAmount) else 0 end +
					case @taxinterface when 'Y' then sum(t.RetgTax) else 0 end
   		 		from bJBIT t with (nolock)
   				join bJBIN n with (nolock) on n.JBCo = t.JBCo and n.BillMonth = t.BillMonth and n.BillNumber = t.BillNumber
   		 		where t.JBCo = @co and t.Contract = @contract and n.InvStatus <> 'D'
   					and (t.BillMonth < @billmth or (t.BillMonth = @billmth and t.BillNumber <= @billnum))
   				end
   
    		if @jbintotal > @currcontract
        		begin
        		exec bspJBTandMTransErrors @co, @billmth, @billnum, null,
        			null, 101, @errmsg output
        		end
    		else
        		begin
				if exists(select 1 from bJBBE with (nolock) where JBCo = @co and BillMonth = @billmth
					and BillNumber = @billnum and BillError = 101)
					begin
        			delete from bJBBE 
					where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
          				and BillError = 101
					end
        		end
    		end
   		end		/* End LimitOpt 'C' Loop */
   
   	/* Before retrieving the next item, if JBCO.PrevUpdateYN = 'Y' update all later bills,
   	   by adding the value of this inserted item to all later bills Previous values.  The
   	   amount of change is the same for each bill and can be updated as a record set. */
   	if @prevupdateYN = 'Y'
   		begin	/* Begin Previous Update Loop */
   		select @firstmth = min(bJBIN.BillMonth)
   		from bJBIN	with (nolock)
   		join bJBIT with (nolock) on bJBIN.JBCo = bJBIT.JBCo and bJBIN.BillMonth = bJBIT.BillMonth and bJBIN.BillNumber = bJBIT.BillNumber
   		where bJBIN.JBCo = @co and bJBIN.Contract = @contract and bJBIN.InvStatus <> 'D'
   			and bJBIT.Item = @item 
   			and ((bJBIN.BillMonth > @billmth) or (bJBIN.BillMonth = @billmth and bJBIN.BillNumber > @billnum))
   
   		if @firstmth is not null
   			begin	
   			select @firstbill = min(bJBIN.BillNumber)
   			from bJBIN with (nolock)
   			join bJBIT with (nolock) on bJBIN.JBCo = bJBIT.JBCo and bJBIN.BillMonth = bJBIT.BillMonth and bJBIN.BillNumber = bJBIT.BillNumber
   			where bJBIN.JBCo = @co and bJBIN.Contract = @contract and bJBIN.InvStatus <> 'D'
   				and bJBIT.Item = @item 
   				and bJBIN.BillMonth = @firstmth and bJBIN.BillNumber > @billnum
   
   			if @firstbill is not null
   				begin
   				update bJBIT
   				/* There is a hole here.  When JBIT records are added manually, some of the Previous
   				   values cannot be inputted by the user.  These will therefore be 0.00 and will
   				   never be accurate by way of normal trigger updates.  To correct these values, user
   				   must return to an earlier bill and perform an Update Previous from the menu.
   				   ************ USERS DO NOT DO THIS AS A RULE ***********/
   				set bJBIT.PrevUnits = bJBIT.PrevUnits + (@invunits), 
   					bJBIT.PrevAmt = bJBIT.PrevAmt + (@invtotal),
   					bJBIT.PrevRetg = bJBIT.PrevRetg + (@invretg), 
					bJBIT.PrevRetgTax = bJBIT.PrevRetgTax + (@invretgtax), 
   					bJBIT.PrevRetgReleased = bJBIT.PrevRetgReleased + (@invrelretg),
					bJBIT.PrevRetgTaxRel = bJBIT.PrevRetgTaxRel + (@invrelretgtax),
   					bJBIT.PrevTax = bJBIT.PrevTax + (@invtax), 
   					bJBIT.PrevDue = bJBIT.PrevDue + (@invdue),
   					bJBIT.PrevWC = bJBIT.PrevWC + (@wc), 
   					bJBIT.PrevWCUnits = bJBIT.PrevWCUnits + (@wcunits),
   					bJBIT.PrevSM = bJBIT.PrevSM + (@sm), 
   					bJBIT.PrevSMRetg = bJBIT.PrevSMRetg + (@smretg),
   					bJBIT.PrevWCRetg = bJBIT.PrevWCRetg + (@wcretg),
   					bJBIT.AuditYN = 'N'
   				from bJBIT
   				join bJBIN with (nolock) on bJBIN.JBCo = bJBIT.JBCo and bJBIN.BillMonth = bJBIT.BillMonth and bJBIN.BillNumber = bJBIT.BillNumber
   				where bJBIT.JBCo = @co and bJBIT.Contract = @contract and bJBIN.InvStatus <> 'D'
   					and bJBIT.Item = @item 
   					and bJBIT.BillMonth = @firstmth and bJBIT.BillNumber = @firstbill
   				if @@error <> 0
   					begin
   					select @errmsg = 'An error occured while updating Previous Amounts on later bills.'
   					goto error
   					end
   
   				update bJBIT
   				set bJBIT.AuditYN = 'Y'
   				from bJBIT	with (nolock)
   				join bJBIN with (nolock) on bJBIN.JBCo = bJBIT.JBCo and bJBIN.BillMonth = bJBIT.BillMonth and bJBIN.BillNumber = bJBIT.BillNumber
   				where bJBIT.JBCo = @co and bJBIT.Contract = @contract and bJBIN.InvStatus <> 'D'
   					and bJBIT.Item = @item 
   					and bJBIT.BillMonth = @firstmth and bJBIT.BillNumber = @firstbill
   				end
   			end
   		end		/* End Previous Update Loop */
   
NextItem:
   	fetch next from bJBIT_insert into @co, @billmth, @billnum, @item, @purgeyn, @audityn
   	end		/* End JBIT inserted Loop */
   
if @openbJBITcursor = 1
   	begin
   	close bJBIT_insert
   	deallocate bJBIT_insert
   	select @openbJBITcursor = 0
   	end
--------------------------------  REM'D FOR ISSUE #22126 ----------------------------------------------
/*
select @co = min(JBCo)
from inserted i
while @co is not null
   	begin
   	select @prevupdateYN = PrevUpdateYN
   	from bJBCO with (nolock)
   	where JBCo = @co
   
	select @billmth = min(BillMonth)
	from inserted i
	where JBCo = @co
	while @billmth is not null
    	begin
     	select @billnum = min(BillNumber)
     	from inserted i
     	where JBCo = @co and BillMonth = @billmth
     	while @billnum is not null
           	begin
			select @arco = ARCo
           	from bJCCO	with (nolock)
           	where JCCo = @co
   			if @arco is null
   				begin
   				select @arco = @co
   				end
   
           	select @contract = n.Contract, @limitopt = c.JBLimitOpt, @artrans = n.ARTrans,
             		@taxinterface = c.TaxInterface, @todate = n.ToDate
           	from bJBIN n with (nolock)
           	join bJCCM c with (nolock) on c.JCCo = n.JBCo and c.Contract = n.Contract
           	where n.JBCo = @co and n.BillMonth = @billmth and n.BillNumber = @billnum

   			if @contract is not null
   				begin
   	       		select @jbintotal = sum(t.AmtBilled) + 
   					case @taxinterface when 'Y' then sum(t.TaxAmount) else 0 end +
					case @taxinterface when 'Y' then sum(t.RetgTax) else 0 end
				from bJBIT t with (nolock)
   				join bJBIN n with (nolock) on n.JBCo = t.JBCo and n.BillMonth = t.BillMonth and n.BillNumber = t.BillNumber
				where t.JBCo = @co and t.Contract = @contract and n.InvStatus <> 'D'
   					and (t.BillMonth < @billmth or (t.BillMonth = @billmth and t.BillNumber <= @billnum))
   				end
   
           	select @item = min(Item)
           	from inserted i
           	where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
           	while @item is not null
				begin
   ------------------------------
              	select @otheritem = min(Item) 
				from bJBIT with (nolock)
				where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
                	and Item <> @item
           		while @otheritem is not null
               		begin
   					select @otheritem = min(Item) 
   					from bJBIT with (nolock)
   					where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
						and Item <> @item and Item > @otheritem
   					end
   ------------------------------
   			NextItem:
         		select @item = min(Item)
         		from inserted i
         		where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Item > @item
         		if @@rowcount = 0 select @item = null
         		end
   
           	select @billnum = min(BillNumber)
           	from inserted i
           	where JBCo = @co and BillMonth = @billmth and BillNumber > @billnum
           	end

     	select @billmth = min(BillMonth)
     	from inserted i
     	where JBCo = @co and BillMonth > @billmth
     	end
   
	select @co = min(JBCo)
	from inserted i
	where JBCo = @co and JBCo > @co
	if @@rowcount = 0 select @co = null
	end
*/
--------------------------------  REM'D FOR ISSUE #22126 ----------------------------------------------
begin_audit:
   
/*Issue 13667*/
Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
Select 'bJBIT', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Item: ' + i.Item, i.JBCo, 'A', null, null, null, getdate(), SUSER_SNAME()
From inserted i
Join bJBCO c on c.JBCo = i.JBCo
Where c.AuditBills = 'Y' and i.AuditYN = 'Y'

return
   
error:
select @errmsg = @errmsg + ' - cannot insert JB Item Detail!'

if @openotheritemcursor = 1
	begin
	close bcOtherItem
	deallocate bcOtherItem
	select @openotheritemcursor = 0
	end

if @openbJBITcursor = 1
	begin
	close bJBIT_insert
	deallocate bJBIT_insert
	select @openbJBITcursor = 0
	end
   
RAISERROR(@errmsg, 11, -1);
rollback transaction
   
   
  
 


GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  TRIGGER [dbo].[btJBITu] ON [dbo].[bJBIT]
FOR UPDATE AS

/**************************************************************
*  This trigger rejects delete of bJBIT (JB Item Totals)
*  if the following error condition exists:
*
*		none
*
*  Updates corresponding fields in JBIN.
*
*  Created by: kb
*  Modified by : kb 1/4/00
*  Modified by : kb 3/24/00 - to update a flag in SLWI if a JBIT record is
*                             changed and a worksheet was i
nitialized for that bill
*		bc 04/19/00 - added update to JBIN.PrevRRel
* 		bc 09/19/00 - check to see if JBIN update is successful
*   	kb 2/8/01 - issue #12255
*   	kb 7/24/1 - issue #13454
*    	kb 9/18/1 - issue #14385
*     	kb 9/18/1 - issue #14664
*     	kb 9/26/1 - issue #14680
*    	ALLENN 11/16/2001 Issue #13667
*    	kb 2/19/2 - issue #16147
*		kb 8/5/2 - issue #18207 - changed view usage to tables
*		SR 10/02/02 - issue #18793 - commented out select debug stmt after 3rd if @billtype
*		TJL 10/29/02 - Issue #18907, Correct LimitOpt Check and Warning Code
*		TJL 11/06/02 - Issue #18740, Exit if (Purge) Column is updated
*		TJL 01/28/03 - Issue #17278, Update Previous Amounts on Later bills.
*		TJL 03/18/03 - Issue #17278, Problem Found, Manual Update set InvStat = 'C' on all bills
*		TJL 03/19/03 - Issue #17278, Dealt with a problem Updating bJBIN PrevValues
*		TJL 03/31/03 - Issue #17278, Dealt with Updating bJBIS PrevValues
*		RBT 08/05/03 - Issue #22019, Change varchar length to 13 for converting bDollar and bUnits values in auditing.
*		TJL 09/08/03 - Issue #22126, Speed enhancement, remove psuedo cursor
*		TJL 01/09/04 - Issue #21076, Part of Updating ChgOrd Adds/Deds and CurrCont/Contractunits on Later Bills
*		TJL 01/12/04 - Issue #23427, If JBIT.Description changes by itself, update JBIS.Description
*		TJL 01/13/04 - Issue #22905, Update bJBIS.Notes directly
*		TJL 03/15/04 - Issue #24051, Correct Keystring, Converted BillMonth
*		TJL 04/27/04 - Issue #24448, Selecting @jbintotal & @jbittotal done only when required.
*		TJL 05/10/04 - Issue #24566, Correct incorrect (convert(varchar(), ____)) statements thru-out
*		TJL 09/05/06 - Issue #120144 (5x - #122500), Do NOT set InvStatus = 'C' when CurrContract changes by itself.
*		TJL 08/01/07 - Issue #125185 Trigger error when Item OverLimit error 101 exists in JBBE
*		TJL 01/07/08 - Issue #120443, Post JBIN Notes and JBIT Notes to Released (2nd R or Credit Invoice) in ARTH, ARTL
*		TJL 07/18/08 - Issue #128287, JB International Sales Tax
*		TJL 12/22/08 - Issue #129896, Add JBIN updates to AmtClaimed, Audit same
*		TJL 08/26/09 - Issue #133896, JBIS Description should be kept the same for Bill Item as well as associated Bill Item ACO's
*
*****************************************************************************************/
declare @errmsg varchar(255), @validcnt int, @errno int, @numrows int, @nullcnt int,
	@co bCompany, @billmth bMonth, @billnum int, @item bContractItem, 
	@invtotal bDollar, @invretg bDollar, @invrelretg bDollar, @invdisc bDollar, @taxbasis bDollar,
	@invtax bDollar, @invdue bDollar, @currcontract bDollar, @prevwc bDollar, @wc bDollar,
	@installed bDollar, @purchased bDollar, @prevsm bDollar, @sm bDollar, @smretg bDollar, @wcretg bDollar,
	@oldinvtotal bDollar, @oldinvretg bDollar, @oldinvrelretg bDollar, @oldinvdisc bDollar,
	@oldtaxbasis bDollar, @oldinvtax bDollar, @oldinvdue bDollar, @oldcurrcontract bDollar,
	@oldprevwc bDollar, @oldwc bDollar, @oldinstalled bDollar, @oldpurchased bDollar, @oldprevsm bDollar, @oldsm bDollar, @oldsmretg bDollar,
	@oldwcretg bDollar, @contract bContract, @billtype char(1), @limitopt char(1),
	@taxinterface bYN, @prevretg bDollar, @oldprevretg bDollar, @prevretgrel bDollar, 
	@oldprevretgrel bDollar, @prevtax bDollar, @oldprevtax bDollar, @prevdue bDollar, 
	@oldprevdue bDollar, @prevsmretg bDollar, @oldprevsmretg bDollar, @prevwcretg bDollar, 
	@oldprevwcretg bDollar, @jbittotal bDollar,	@jbintotal bDollar, @otheritem bContractItem,
	@todate bDate, @otherjbittotal bDollar,	@othercurrcontract bDollar,
	@prevupdateYN bYN, @oldprevunits bUnits, @oldprevwcunits bUnits, @oldprevamt bDollar,
	@invunits bUnits, @wcunits bUnits, @prevunits bUnits, @prevwcunits bUnits, @prevamt bDollar,
	@oldinvunits bUnits, @oldwcunits bUnits, @chginvstat bYN, @openbJBITcursor int, @openotheritemcursor int,
	@invamtclaimed bDollar, @oldinvamtclaimed bDollar, @jbisacocount int,
	/* JB International Sales Tax */
	@invretgtax bDollar, @invrelretgtax bDollar, @prevretgtax bDollar, @prevretgtaxrel bDollar,
	@oldinvretgtax bDollar, @oldinvrelretgtax bDollar, @oldprevretgtax bDollar, @oldprevretgtaxrel bDollar

select @numrows = @@rowcount, @openbJBITcursor = 0, @openotheritemcursor = 0
    
if @numrows = 0 return
set nocount on
/*Issue 13667*/
If Update(Purge)
   	begin
   	return
   	end
   
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
   	End
   
If Update(Item)
   	Begin
   	select @errmsg = 'Cannot change Item'
   	GoTo error
   	End
    
select @prevretg = 0, @prevretgtax = 0, @oldprevretg = 0, @oldprevretgtax = 0, @prevtax = 0, @oldprevtax = 0,
   	@prevdue = 0, @oldprevdue = 0, @prevwcretg = 0, @oldprevwcretg = 0

-- Validate ReasonCode
if update(ReasonCode)
	begin
 	select @validcnt = count(*) from inserted i
	JOIN bHQRC r with (nolock) ON i.ReasonCode = r.ReasonCode
 	select @nullcnt = count(*) from  inserted i where i.ReasonCode is null
 	if @validcnt + @nullcnt <> @numrows
		begin
		select @errmsg = 'Reason Code is Invalid '
		goto error
		end
 	end
    
if update(AmtBilled) or update(RetgBilled) or update(RetgTax) or update(RetgRel) or update(RetgTaxRel) or update(Discount)
	or update(TaxBasis) or update(TaxAmount) or update(AmountDue) or update(CurrContract)
	or update(WC) or update(Installed) or update(Purchased) or update(PrevSM)
	or update(SM) or update(SMRetg) or update(PrevWC) or update(WCRetg)
	or update(PrevRetg) or update(PrevRetgTax) or update(PrevTax) or update(PrevDue) or update(PrevWCRetg)
	or update(PrevRetgReleased) or update(PrevRetgTaxRel) or update(PrevSMRetg) or update(UnitsBilled)
	or update(PrevUnits) or update(PrevAmt) or update(PrevWCUnits) or update(WCUnits)
	or update(AmtClaimed) or update(Description) or update(Notes)
	begin	/* Begin Update Loop */
   
   	declare bJBIT_insert cursor local fast_forward for
   	select JBCo, BillMonth, BillNumber, Item
   	from inserted
   	
   	open bJBIT_insert
   	select @openbJBITcursor = 1
   	
   	fetch next from bJBIT_insert into @co, @billmth, @billnum, @item
   	while @@fetch_status = 0
   		begin	/* Begin JBIT Inserted Loop */
   		select @jbisacocount = 0
   		
   		/************* Get some preliminary values **************/
		/* Get PrevUpdateYN flag from JBCO.  It will be used later to determine if Previous Amount
		   values need to be updated in later bills. */
		select @prevupdateYN = PrevUpdateYN
		from bJBCO with (nolock)
		where JBCo = @co
   
   		/* reset the Change Invoice Status flag to 'N' for each new bill */
   		select @chginvstat = 'N'
   
   		select @contract = n.Contract, @limitopt = c.JBLimitOpt,
			@taxinterface = c.TaxInterface, @todate = n.ToDate
		from bJBIN n with (nolock)
   		join bJCCM c with (nolock) on c.JCCo = n.JBCo and c.Contract = n.Contract
		where n.JBCo = @co and n.BillMonth = @billmth and n.BillNumber = @billnum

   		select @invtotal = i.AmtBilled, @invretg = i.RetgBilled, @invretgtax = i.RetgTax,
       		@invrelretg = i.RetgRel, @invrelretgtax = i.RetgTaxRel,
			@invdisc = i.Discount, @taxbasis = i.TaxBasis,
       		@invtax = i.TaxAmount, @invdue = i.AmountDue,
       		@currcontract = i.CurrContract, @wc = i.WC, @installed = i.Installed,
       		@purchased = i.Purchased, @prevsm = i.PrevSM, @sm = i.SM,
       		@smretg = i.SMRetg, @prevwc = i.PrevWC, @wcretg = i.WCRetg,
       		@oldinvtotal = d.AmtBilled, @oldinvretg = d.RetgBilled, @oldinvretgtax = d.RetgTax,
   	  		@oldinvrelretg = d.RetgRel, @oldinvrelretgtax = d.RetgTaxRel, @oldinvdisc = d.Discount,
       		@oldtaxbasis = d.TaxBasis, @oldinvtax = d.TaxAmount,
       		@oldinvdue = d.AmountDue, @oldcurrcontract = d.CurrContract,
   	  		@oldprevwc = d.PrevWC, @oldwc = d.WC, @oldinstalled = d.Installed,
       		@oldpurchased = d.Purchased, @oldsm = d.SM, @oldprevsm = d.PrevSM,
   	  		@oldsmretg = d.SMRetg, @oldwcretg = d.WCRetg, @prevretg = i.PrevRetg, @prevretgtax = i.PrevRetgTax,
			@oldprevretg = d.PrevRetg, @oldprevretgtax = d.PrevRetgTax, @prevtax = i.PrevTax, @oldprevtax = d.PrevTax,
     		@prevdue = i.PrevDue, @oldprevdue = d.PrevDue, @prevwcretg = i.PrevWCRetg, @oldprevwcretg = d.PrevWCRetg,
    		@prevretgrel = i.PrevRetgReleased, @prevretgtaxrel = i.PrevRetgTaxRel, @oldprevretgrel = d.PrevRetgReleased,
    		@oldprevretgtaxrel = d.PrevRetgTaxRel, @prevsmretg = i.PrevSMRetg, @oldprevsmretg = d.PrevSMRetg,
   			@invunits = i.UnitsBilled, @oldprevunits = d.PrevUnits, 
   			@oldprevamt = d.PrevAmt, @wcunits = i.WCUnits, @oldprevwcunits = d.PrevWCUnits,
   			@prevunits = i.PrevUnits, @prevamt = i.PrevAmt, @prevwcunits = i.PrevWCUnits,
   			@oldinvunits = d.UnitsBilled, @oldwcunits = d.WCUnits,
			@invamtclaimed = i.AmtClaimed, @oldinvamtclaimed = d.AmtClaimed
   		from inserted i
   		join deleted d on i.JBCo = d.JBCo and i.BillMonth = d.BillMonth and i.BillNumber = d.BillNumber 
   			and i.Item = d.Item
		where  i.JBCo = @co and i.BillMonth = @billmth and i.BillNumber = @billnum and i.Item = @item

   		/* For this BillMonth, BillNumber, look at the updated columns for each item.  If the updated
   		   column is not a previous amounts column, then this bill will need to be reinterfaced and so
   		   the InvStatus will be set to 'C'.  If only Previous amounts are being adjusted, then this
   		   will never happen. */
   		if @chginvstat = 'N'
   			begin
   			if @invtotal <> @oldinvtotal or @invretg <> @oldinvretg or @invrelretg <> @oldinvrelretg 
				or @invretgtax <> @oldinvretgtax or @invrelretgtax <> @oldinvrelretgtax 
				or @invdisc <> @oldinvdisc or @taxbasis <> @oldtaxbasis or	@invtax <> @oldinvtax or @invdue <> @oldinvdue
   				or @wc <> @oldwc or @installed <> @oldinstalled or @purchased <> @oldpurchased or @sm <> @oldsm or @smretg <> @oldsmretg 
   				or @wcretg <> @oldwcretg or @invunits <> @oldinvunits or @wcunits <> @oldwcunits 
				or update(Notes) select @chginvstat = 'Y'
   			end
    
   		/* Updating bJBIN at this point with inserted/deleted values from this item can also
   		   be used later to determine Total AmountBill for this Contract.  Once this
   		   update occurs, newly updated values become available for evaluation. */     			 	
   		update bJBIN
   		set InvStatus = case @chginvstat when 'Y' then
   				(case InvStatus when 'I' then 'C' else InvStatus end) else InvStatus end,
			InvTotal = InvTotal+@invtotal-@oldinvtotal, InvRetg = InvRetg + @invretg-@oldinvretg,
			RetgTax = RetgTax + @invretgtax-@oldinvretgtax, RetgTaxRel = RetgTaxRel + @invrelretgtax-@oldinvrelretgtax,	
   	     	RetgRel = RetgRel + @invrelretg-@oldinvrelretg, InvDisc = InvDisc + @invdisc-@oldinvdisc,
   	     	TaxBasis = TaxBasis + @taxbasis - @oldtaxbasis, InvTax = InvTax + @invtax - @oldinvtax,
   	     	InvDue = InvDue + @invdue - @oldinvdue, CurrContract = CurrContract + @currcontract - @oldcurrcontract,
   	     	PrevWC = PrevWC + @prevwc - @oldprevwc, WC = WC + @wc - @oldwc, Installed = Installed + @installed - @oldinstalled,
   	     	Purchased = Purchased + @purchased - @oldpurchased,
   	     	PrevSM = PrevSM + @prevsm - @oldprevsm, SM = SM + @sm - @oldsm, SMRetg = SMRetg + @smretg - @oldsmretg,
   	     	WCRetg = WCRetg + @wcretg - @oldwcretg,
   	     	PrevAmt = PrevAmt + @prevwc + @prevsm - @oldprevwc - @oldprevsm,
			PrevRetg = PrevRetg + @prevretg - @oldprevretg, PrevRetgTax = PrevRetgTax + @prevretgtax - @oldprevretgtax,
      		PrevSMRetg = PrevSMRetg + @prevsmretg - @oldprevsmretg,
      		PrevTax = PrevTax + @prevtax - @oldprevtax,
			PrevDue = PrevDue + @prevdue - @oldprevdue, PrevWCRetg = PrevWCRetg + @prevwcretg - @oldprevwcretg,
       		PrevRRel = PrevRRel + @prevretgrel - @oldprevretgrel, PrevRetgTaxRel = PrevRetgTaxRel + @prevretgtaxrel - @oldprevretgtaxrel,
			AmtClaimed = AmtClaimed+@invamtclaimed-@oldinvamtclaimed,
       		AuditYN = 'N'
    		from bJBIN	
   	  	where JBCo = @co and BillNumber = @billnum and BillMonth = @billmth
    
       	if @@rowcount = 0
   	      	begin
   	      	select @errmsg = 'Error updating JBIN'
   	      	goto error
   	      	end
    
		update bJBIN 
   		set AuditYN = 'Y'
       	from bJBIN	with (nolock)
   		where JBCo = @co and BillNumber = @billnum and BillMonth = @billmth
    
   		/* need an update statement here before trying to insert into jbis */
		update bJBIS
      	set Description = t.Description, UnitsBilled = t.UnitsBilled, AmtBilled = t.AmtBilled, 
			RetgBilled = t.RetgBilled, RetgTax = t.RetgTax, RetgRel = t.RetgRel, RetgTaxRel = t.RetgTaxRel,		
			Discount = t.Discount, TaxBasis = t.TaxBasis, TaxAmount = t.TaxAmount,
        	AmountDue = t.AmountDue, PrevUnits = t.PrevUnits, PrevAmt = t.PrevAmt, 
			PrevRetg = t.PrevRetg, PrevRetgTax = t.PrevRetgTax,	PrevRetgReleased = t.PrevRetgReleased, PrevRetgTaxRel = t.PrevRetgTaxRel, 
			PrevTax = t.PrevTax, PrevDue = t.PrevDue, ARLine = t.ARLine,
         	ARRelRetgLine = t.ARRelRetgLine, ARRelRetgCrLine = t.ARRelRetgCrLine, TaxGroup = t.TaxGroup,
			TaxCode = t.TaxCode, CurrContract = t.CurrContract, ContractUnits = t.ContractUnits, PrevWC = t.PrevWC,
       		PrevWCUnits = t.PrevWCUnits, WC = t.WC, WCUnits = t.WCUnits, PrevSM = t.PrevSM, Installed = t.Installed,
 	        Purchased = t.Purchased, SM = t.SM, SMRetg = t.SMRetg, PrevSMRetg = t.PrevSMRetg,
      		PrevWCRetg = t.PrevWCRetg, WCRetg = t.WCRetg, WCRetPct = t.WCRetPct,
         	BillGroup = t.BillGroup, Contract = b.Contract
    	from inserted t
   		join bJBIS s with (nolock) on t.JBCo = s.JBCo and t.BillMonth = s.BillMonth 
   			and t.BillNumber = s.BillNumber and t.Item = s.Item
   		join bJBIN b with (nolock) on t.JBCo = b.JBCo and t.BillNumber = b.BillNumber 
   			and t.BillMonth = b.BillMonth
		where s.Job = '' and s.ACO = ''	and s.ACOItem = '' 	
   			and t.JBCo = @co and t.BillMonth = @billmth and t.BillNumber = @billnum and t.Item = @item
              	
  		if @@rowcount = 0
			begin
			insert bJBIS (JBCo,BillMonth, BillNumber, Job, Item, ACO, ACOItem, Description,
       			UnitsBilled, AmtBilled, RetgBilled, RetgTax, RetgRel, RetgTaxRel, Discount, TaxBasis, TaxAmount, AmountDue, PrevUnits,
     			PrevAmt, PrevRetg, PrevRetgTax, PrevRetgReleased, PrevRetgTaxRel, PrevTax, PrevDue, ARLine, ARRelRetgLine, ARRelRetgCrLine,
     			TaxGroup, TaxCode, CurrContract, ContractUnits, PrevWC, PrevWCUnits, WC, WCUnits,
           		PrevSM, Installed, Purchased, SM,
        		SMRetg, PrevSMRetg, PrevWCRetg, WCRetg,WCRetPct,
         		BillGroup, Contract, ChgOrderUnits, ChgOrderAmt)
         	select i.JBCo, i.BillMonth, i.BillNumber, '', i.Item, '', '', i.Description,
           		i.UnitsBilled, i.AmtBilled, i.RetgBilled, i.RetgTax, i.RetgRel, i.RetgTaxRel,
 	        	i.Discount, i.TaxBasis, i.TaxAmount, i.AmountDue, i.PrevUnits,
         		i.PrevAmt, i.PrevRetg, i.PrevRetgTax, i.PrevRetgReleased, i.PrevRetgTaxRel, 
				i.PrevTax, i.PrevDue, i.ARLine, i.ARRelRetgLine, i.ARRelRetgCrLine,
         		i.TaxGroup, i.TaxCode, i.CurrContract, i.ContractUnits, i.PrevWC, i.PrevWCUnits, i.WC, i.WCUnits,
           		i.PrevSM, i.Installed, i.Purchased, i.SM,
 	        	i.SMRetg, i.PrevSMRetg, i.PrevWCRetg, i.WCRetg, i.WCRetPct,
            	i.BillGroup, b.Contract, 0, 0
        	from inserted i
			join bJBIN b with (nolock) on i.JBCo = b.JBCo and i.BillMonth = b.BillMonth and i.BillNumber = b.BillNumber
    		where i.JBCo = @co and i.BillMonth = @billmth and i.BillNumber = @billnum and i.Item = @item
 	        end
   
		/* A user may change the Item Description on the JBIT Bill Item.  We need to update any existing Change Order
		   records in the JBIS table with this new description value. */
		select @jbisacocount = count(1)
		from bJBIS with (nolock)
		where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Item = @item and
			isnull(Job, '') <> '' and isnull(ACO, '') <> '' and isnull(ACOItem, '') <> ''
		if @jbisacocount <> 0
			begin
			update s
			set Description = t.Description
			from bJBIS s with (nolock)
			join inserted t on t.JBCo = s.JBCo and t.BillMonth = s.BillMonth and t.BillNumber = s.BillNumber and t.Item = s.Item
			where s.JBCo = @co and s.BillMonth = @billmth and s.BillNumber = @billnum and s.Item = @item and
				isnull(s.Job, '') <> '' and isnull(s.ACO, '') <> '' and isnull(s.ACOItem, '') <> ''
			
			if @@rowcount <> @jbisacocount
				begin
       			select @errmsg = 'Error updating JBIS ACO description.'
       			goto error
       			end
			end
			
		/* Update Notes separately, errors if done above. */
		if update(Notes)
			begin
			update bJBIS set Notes = t.Notes 
			from inserted i 
			join bJBIS s with (nolock) on i.JBCo = s.JBCo and i.BillMonth = s.BillMonth 
				and i.BillNumber = s.BillNumber and i.Item = s.Item
			join bJBIT t with (nolock) on i.JBCo = t.JBCo and i.BillMonth = t.BillMonth 
				and i.BillNumber = t.BillNumber and i.Item = t.Item
			where s.Job = '' and s.ACO = ''	and s.ACOItem = '' 	
				and i.JBCo = @co and i.BillMonth = @billmth and i.BillNumber = @billnum and i.Item = @item
			end
   
  		/* see if this bill exists in any SL Worksheet Item, if so update the
           BillChangedYN flag to 'Y' */
    	if update(AmtBilled) or update(RetgBilled) or update(RetgTax) or update(UnitsBilled)
       		or update(SM) or update(SMRetg) or update(PrevAmt) or update(PrevUnits)
         	or update(PrevRetg) or update(PrevRetgTax) or update(PrevSM) or update(PrevSMRetg)
          	or update(WC) or update(WCUnits) or update(PrevWC) or update(PrevWCUnits)
			or update(Installed) or update(Purchased) or update(WCRetg) or update(PrevWCRetg)
          	or update(TaxBasis) 
    						
   			/* Should this be part of the above statement?? */
   			/* or update(RetgRel) or update(Discount)
   			or update(TaxAmount) or update(AmountDue) or update(CurrContract)
   			or update(PrevTax) or update(PrevDue)or update(PrevRetgReleased) */
    	
			begin	/* Begin Lessor Update Loop */
			update bSLWI 
   			set BillChangedYN = 'Y' 
   			from bSLWI i with (nolock)
			join bSLWH h with (nolock) on h.SLCo = i.SLCo and h.SL = i.SL 
   			where h.JCCo = @co and BillMonth = @billmth and BillNumber = @billnum
               	and BillChangedYN = 'N'
    
     		/* If limitopt = 'I', has the AmtBilled exceeded the Total Amount for this item */
     		if @limitopt = 'I'
        		begin	/* Begin LimitOpt 'I' Loop */
        		select @billtype = BillType, @currcontract = ContractAmt	--Includes Change Orders
          		from bJCCI with (nolock)
				where JCCo = @co and Contract = @contract and Item = @item
   
        		if @billtype in ('B','T')
            		begin
   					/* Issue #18907:  As the additional value for this Item is processed here, 
   					   JBIT already contains its additional value at this time.  Just go to bJBIT 
   					   directly for the current sum(AmtBilled) for this item. (Represents the full 
   					   AmtBilled for this item up to this moment.  We will not include Bills marked for
   					   delete and evaluation is intentionally done from this bill backwards.
   
   			   		   We Get Item Total only when LimitOpt is set for Item and only for Items marked
   			   		   as "B" or "T" (Not Progress).  This helps reduce Initialization time when
   			   		   the value is not to be used. */
   					select @jbittotal = sum(t.AmtBilled) + 
   						case @taxinterface when 'Y' then sum(t.TaxAmount) else 0 end +
						case @taxinterface when 'Y' then sum(t.RetgTax) else 0 end
   		     		from bJBIT t with (nolock)
   					join bJBIN n with (nolock) on n.JBCo = t.JBCo and n.BillMonth = t.BillMonth and n.BillNumber = t.BillNumber
   		     		where t.JBCo = @co and t.Contract = @contract and t.Item = @item and n.InvStatus <> 'D'
   						and (t.BillMonth < @billmth or (t.BillMonth = @billmth and t.BillNumber <= @billnum))
   
            		if @jbittotal > @currcontract
                		begin
                		exec bspJBTandMTransErrors @co, @billmth, @billnum, null,
                			null, 101, @errmsg output
                		end
            		else
    					begin
   						/* Unfortunately if This Item is not over limit AND if an 'OverLimit'
   						   error DOES exist for this bill, we must check all items to see if
   							   this conditions still exists since if this was the OverLimit item
   						   then we would want to remove the error in bJBBE.  Inefficient, Yes.
   						   BUT, most customers won't be doing this, and we will jump out of
   						   loop at earliest possible moment.  (Changing this would be desirable
   						   but pretty consuming for just a warning!) */
   						if exists(select 1 from bJBBE with (nolock) where JBCo = @co and BillMonth = @billmth
   								and BillNumber = @billnum and BillError = 101)
   							begin
   							declare bcOtherItem cursor local fast_forward for
   							select Item
   							from bJBIT with (nolock)
   							where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
   		                     	and Item <> @item					
   							
   							open bcOtherItem
   							select @openotheritemcursor = 1
   							
   							fetch next from bcOtherItem into @otheritem
   							while @@fetch_status = 0
   								begin
   								/* Get OtherItem total from bJBIT for this BillNumber or Earlier 
   								   not including those marked for delete. */
   								select @otherjbittotal = sum(t.AmtBilled) + 
   									case @taxinterface when 'Y' then sum(t.TaxAmount) else 0 end +
									case @taxinterface when 'Y' then sum(t.RetgTax) else 0 end
   				         		from bJBIT t with (nolock)
   								join bJBIN n with (nolock) on n.JBCo = t.JBCo and n.BillMonth = t.BillMonth and n.BillNumber = t.BillNumber
   				         		where t.JBCo = @co and t.Contract = @contract and t.Item = @otheritem and n.InvStatus <> 'D'
   									and (t.BillMonth < @billmth or (t.BillMonth = @billmth and t.BillNumber <= @billnum))
    									
   								/* Get OtherItem Contract Amount for comparison */
   			             		select @othercurrcontract = ContractAmt		--Includes Change Orders
   			               		from bJCCI with (nolock)
   								where JCCo = @co and Contract = @contract and Item = @otheritem
    			
   								/* Compare the two */
   								if @otherjbittotal > @othercurrcontract
   									begin
   									/* Error still valid, no deletion will occur */
   									if @openotheritemcursor = 1
   										begin
   										close bcOtherItem
   										deallocate bcOtherItem
   										select @openotheritemcursor = 0
   										end
   									goto NextItem
   									end
    											
   								/* An error exists.  Neither the actual Item or this OtherItem is 
   								   OverLimit so Get Next OtherItem for check. */
   								fetch next from bcOtherItem into @otheritem
   								end
   
   							if @openotheritemcursor = 1
   								begin
   								close bcOtherItem
   								deallocate bcOtherItem
   								select @openotheritemcursor = 0
   								end
   		
   							/* An error exists.  Neither the actual Item or any OtherItem is 
   							   OverLimit on this bill so go ahead and delete the error from bJBBE. */
                    		delete bJBBE 
   							where JBCo = @co  and BillMonth = @billmth and BillNumber = @billnum
   								and BillError = 101
                    		end
		              	end
					end
		    	end		/* End LimitOpt 'I' Loop */
    		
   			/* If limitopt = 'C', has the AmtBilled exceeded the Total Amount for this Contract */
      		if @limitopt = 'C'
        		begin	/* Begin LimitOpt 'C' Loop */
        		select @billtype = BillType
          		from bJBIN with (nolock)
   				where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
    		
				select @currcontract = sum(ContractAmt)		--Includes Change Orders
				from bJCCI with (nolock)
   				where JCCo = @co and Contract = @contract
    		
        		if @billtype in ('B','T')
            		begin
					/* At this moment, the revised item value is available in bJBIT.  The 
					   sum(AmtBilled) is current including this update. 

		   			   We Get combined Item Totals only when LimitOpt is set for Contract and only for
		   			   BillTypes "B" or "T" (Not Progress).  This helps reduce Initialization time when
		   			   the value is not to be used. */
					if @contract is not null
						begin	
						select @jbintotal = sum(t.AmtBilled) + 
							case @taxinterface when 'Y' then sum(t.TaxAmount) else 0 end +
							case @taxinterface when 'Y' then sum(t.RetgTax) else 0 end
						from bJBIT t with (nolock)
						join bJBIN n with (nolock) on n.JBCo = t.JBCo and n.BillMonth = t.BillMonth and n.BillNumber = t.BillNumber
						where t.JBCo = @co and t.Contract = @contract and n.InvStatus <> 'D'
							and (t.BillMonth < @billmth or (t.BillMonth = @billmth and t.BillNumber <= @billnum))
						end
   
            		if @jbintotal > @currcontract
                		begin
                		exec bspJBTandMTransErrors @co, @billmth, @billnum, null,
                			null, 101, @errmsg output
                		end
            		else
						begin
   						if exists(select 1 from bJBBE with (nolock) where JBCo = @co and BillMonth = @billmth
   								and BillNumber = @billnum and BillError = 101)
   							begin
                    		delete from bJBBE 
   							where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
                      			and BillError = 101
   							end
                		end
            		end
		      	end		/* End LimitOpt 'C' Loop */
			end		/* Begin Lessor Update Loop */
    
   		/* Before retrieving the next item, if JBCO.PrevUpdateYN = 'Y' update all later bills,
   		   adding the value of this (inserted - deleted) changed item to all later bills Previous values.  The
   		   amount of change is the same for each bill and can be updated as a record set. */
   		if @prevupdateYN = 'Y' and
			/* Need the following so as not to unecessarily update Prev Amounts on all Later bills
			   when only the Items CurrContract and ContractUnits are being adjusted because
			   a Change Order has been added or modified.  Contract amounts for Later Bills are
			   handled separately through bspJBUpdatePrevContractValues but must update 
			   JBIT.CurrContract and JBIT.ContractUnits for each Later Bill.  Previous Values
			   below, typically are not modified during this particular process. */
			(update(AmtBilled) or update(RetgBilled) or update(RetgTax) or update(RetgRel) or update(RetgTaxRel)
		 	or update(Discount) or update(TaxBasis) or update(TaxAmount) or update(AmountDue) 
		 	or update(WC) or update(Installed) or update(Purchased) or update(PrevSM)
		 	or update(SM) or update(SMRetg) or update(PrevWC) or update(WCRetg)
		 	or update(PrevRetg) or update(PrevRetgTax) or update(PrevTax) or update(PrevDue) or update(PrevWCRetg)
		 	or update(PrevRetgReleased) or update(PrevRetgTaxRel) or update(PrevSMRetg) or update(UnitsBilled)
		 	or update(PrevUnits) or update(PrevAmt) or update(PrevWCUnits) or update(WCUnits))
   			begin	/* Begin Previous Update Loop */
   			/* When updating a table from within its own trigger, the trigger is suspended for
   			   those updates.  Therefore, any tables normally updated by the trigger 
   			   MUST be updated directly.  This is the case below. */
   			update bJBIT
   			set bJBIT.PrevUnits = bJBIT.PrevUnits + ((@prevunits - @oldprevunits) + (@invunits - @oldinvunits)), 
   				bJBIT.PrevAmt = bJBIT.PrevAmt + ((@prevamt - @oldprevamt) + (@invtotal - @oldinvtotal)),
   				bJBIT.PrevRetg = bJBIT.PrevRetg + ((@prevretg - @oldprevretg) + (@invretg - @oldinvretg)), 
				bJBIT.PrevRetgTax = bJBIT.PrevRetgTax + ((@prevretgtax - @oldprevretgtax) + (@invretgtax - @oldinvretgtax)),
   				bJBIT.PrevRetgReleased = bJBIT.PrevRetgReleased + ((@prevretgrel - @oldprevretgrel) + (@invrelretg - @oldinvrelretg)),
				bJBIT.PrevRetgTaxRel = bJBIT.PrevRetgTaxRel + ((@prevretgtaxrel - @oldprevretgtaxrel) + (@invrelretgtax - @oldinvrelretgtax)),
   				bJBIT.PrevTax = bJBIT.PrevTax + ((@prevtax - @oldprevtax) + (@invtax - @oldinvtax)), 
   				bJBIT.PrevDue = bJBIT.PrevDue + ((@prevdue - @oldprevdue) + (@invdue - @oldinvdue)),
   				bJBIT.PrevWC = bJBIT.PrevWC + ((@prevwc - @oldprevwc) + (@wc - @oldwc)), 
   				bJBIT.PrevWCUnits = bJBIT.PrevWCUnits + ((@prevwcunits - @oldprevwcunits) + (@wcunits - @oldwcunits)),
   				bJBIT.PrevSM = bJBIT.PrevSM + ((@prevsm - @oldprevsm) + (@sm - @oldsm)), 
   				bJBIT.PrevSMRetg = bJBIT.PrevSMRetg + ((@prevsmretg - @oldprevsmretg) + (@smretg - @oldsmretg)),
   				bJBIT.PrevWCRetg = bJBIT.PrevWCRetg + ((@prevwcretg - @oldprevwcretg) + (@wcretg - @oldwcretg)),
   				bJBIT.AuditYN = 'N'
   			from bJBIT	
   			join bJBIN  with (nolock) on bJBIN.JBCo = bJBIT.JBCo and bJBIN.BillMonth = bJBIT.BillMonth and bJBIN.BillNumber = bJBIT.BillNumber
   			where bJBIT.JBCo = @co and bJBIT.Contract = @contract and bJBIN.InvStatus <> 'D'
   				and bJBIT.Item = @item 
   				and ((bJBIT.BillMonth > @billmth) or (bJBIT.BillMonth = @billmth and bJBIT.BillNumber > @billnum))
   			if @@error <> 0
   				begin
   				select @errmsg = 'An error occured while updating Previous Amounts on later bills.'
   				goto error
   				end
    
   			update bJBIT
   			set bJBIT.AuditYN = 'Y'
   			from bJBIT with (nolock)
   			join bJBIN with (nolock) on bJBIN.JBCo = bJBIT.JBCo and bJBIN.BillMonth = bJBIT.BillMonth and bJBIN.BillNumber = bJBIT.BillNumber
   			where bJBIT.JBCo = @co and bJBIT.Contract = @contract and bJBIN.InvStatus <> 'D'
   				and bJBIT.Item = @item 
   				and ((bJBIT.BillMonth > @billmth) or (bJBIT.BillMonth = @billmth and bJBIT.BillNumber > @billnum))
    
   			update bJBIS
   			set bJBIS.PrevUnits = bJBIS.PrevUnits + ((@prevunits - @oldprevunits) + (@invunits - @oldinvunits)), 
   				bJBIS.PrevAmt = bJBIS.PrevAmt + ((@prevamt - @oldprevamt) + (@invtotal - @oldinvtotal)),
   				bJBIS.PrevRetg = bJBIS.PrevRetg + ((@prevretg - @oldprevretg) + (@invretg - @oldinvretg)), 
				bJBIS.PrevRetgTax = bJBIS.PrevRetgTax + ((@prevretgtax - @oldprevretgtax) + (@invretgtax - @oldinvretgtax)), 
   				bJBIS.PrevRetgReleased = bJBIS.PrevRetgReleased + ((@prevretgrel - @oldprevretgrel) + (@invrelretg - @oldinvrelretg)),
				bJBIS.PrevRetgTaxRel = bJBIS.PrevRetgTaxRel + ((@prevretgtaxrel - @oldprevretgtaxrel) + (@invrelretgtax - @oldinvrelretgtax)),
   				bJBIS.PrevTax = bJBIS.PrevTax + ((@prevtax - @oldprevtax) + (@invtax - @oldinvtax)), 
   				bJBIS.PrevDue = bJBIS.PrevDue + ((@prevdue - @oldprevdue) + (@invdue - @oldinvdue)),
   				bJBIS.PrevWC = bJBIS.PrevWC + ((@prevwc - @oldprevwc) + (@wc - @oldwc)), 
   				bJBIS.PrevWCUnits = bJBIS.PrevWCUnits + ((@prevwcunits - @oldprevwcunits) + (@wcunits - @oldwcunits)),
   				bJBIS.PrevSM = bJBIS.PrevSM + ((@prevsm - @oldprevsm) + (@sm - @oldsm)), 
   				bJBIS.PrevSMRetg = bJBIS.PrevSMRetg + ((@prevsmretg - @oldprevsmretg) + (@smretg - @oldsmretg)),
   				bJBIS.PrevWCRetg = bJBIS.PrevWCRetg + ((@prevwcretg - @oldprevwcretg) + (@wcretg - @oldwcretg))
   			from bJBIS
   			join bJBIN with (nolock) on bJBIN.JBCo = bJBIS.JBCo and bJBIN.BillMonth = bJBIS.BillMonth and bJBIN.BillNumber = bJBIS.BillNumber
   			where bJBIS.JBCo = @co and bJBIS.Contract = @contract and bJBIN.InvStatus <> 'D'
   				and bJBIS.Item = @item 
   				and ((bJBIS.BillMonth > @billmth) or (bJBIS.BillMonth = @billmth and bJBIS.BillNumber > @billnum))
   				and bJBIS.Job = '' and bJBIS.ACO = '' and bJBIS.ACOItem = ''
   			if @@error <> 0
   				begin
   				select @errmsg = 'An error occured while updating Previous Amounts on later bills.'
   				goto error
   				end
    
   			update bJBIN
   			set bJBIN.PrevAmt = bJBIN.PrevAmt + ((@prevamt - @oldprevamt) + (@invtotal - @oldinvtotal)),
   				bJBIN.PrevRetg = bJBIN.PrevRetg + ((@prevretg - @oldprevretg) + (@invretg - @oldinvretg)),
				bJBIN.PrevRetgTax = bJBIN.PrevRetgTax + ((@prevretgtax - @oldprevretgtax) + (@invretgtax - @oldinvretgtax)),
   				bJBIN.PrevRRel = bJBIN.PrevRRel + ((@prevretgrel - @oldprevretgrel) + (@invrelretg - @oldinvrelretg)),
				bJBIN.PrevRetgTaxRel = bJBIN.PrevRetgTaxRel + ((@prevretgtaxrel - @oldprevretgtaxrel) + (@invrelretgtax - @oldinvrelretgtax)),
   				bJBIN.PrevTax = bJBIN.PrevTax + ((@prevtax - @oldprevtax) + (@invtax - @oldinvtax)),
   				bJBIN.PrevDue = bJBIN.PrevDue + ((@prevdue - @oldprevdue) + (@invdue - @oldinvdue)),
   				bJBIN.PrevWC = bJBIN.PrevWC + ((@prevwc - @oldprevwc) + (@wc - @oldwc)),
   				bJBIN.PrevSM = bJBIN.PrevSM + ((@prevsm - @oldprevsm) + (@sm - @oldsm)),
   				bJBIN.PrevSMRetg = bJBIN.PrevSMRetg + ((@prevsmretg - @oldprevsmretg) + (@smretg - @oldsmretg)),
   				bJBIN.PrevWCRetg = bJBIN.PrevWCRetg + ((@prevwcretg - @oldprevwcretg) + (@wcretg - @oldwcretg)),
   				bJBIN.AuditYN = 'N'
   			from bJBIN
   			join bJBIT with (nolock) on bJBIN.JBCo = bJBIT.JBCo and bJBIN.BillMonth = bJBIT.BillMonth and bJBIN.BillNumber = bJBIT.BillNumber
   			where bJBIN.JBCo = @co and bJBIN.Contract = @contract and bJBIN.InvStatus <> 'D'
   				and bJBIT.Item = @item
   				and ((bJBIT.BillMonth > @billmth) or (bJBIT.BillMonth = @billmth and bJBIT.BillNumber > @billnum))
   			if @@error <> 0
   				begin
   				select @errmsg = 'An error occured while updating Previous Amounts on later bills.'
   				goto error
   				end
    
   			update bJBIN
   			set bJBIN.AuditYN = 'Y'
   			from bJBIN	with (nolock)
   			join bJBIT with (nolock) on bJBIN.JBCo = bJBIT.JBCo and bJBIN.BillMonth = bJBIT.BillMonth and bJBIN.BillNumber = bJBIT.BillNumber
   			where bJBIN.JBCo = @co and bJBIN.Contract = @contract and bJBIN.InvStatus <> 'D'
   				and bJBIT.Item = @item
   				and ((bJBIT.BillMonth > @billmth) or (bJBIT.BillMonth = @billmth and bJBIT.BillNumber > @billnum))
			end		/* End Previous Update Loop */
   
	NextItem:
		fetch next from bJBIT_insert into @co, @billmth, @billnum, @item
		end		/* End JBIT Inserted Loop */
   
	if @openbJBITcursor = 1
		begin
		close bJBIT_insert
		deallocate bJBIT_insert
		select @openbJBITcursor = 0
		end
   
   	end		/* End Update Loop */
   
--------------------------------  REM'D FOR ISSUE #22126 ----------------------------------------------
/*
 	select @co = min(JBCo) 
	from inserted
	while @co is not null
    	begin
   
		select @prevupdateYN = PrevUpdateYN
		from bJBCO with (nolock)
		where JBCo = @co

     	select @billmth = min(BillMonth) 
		from inserted 
		where JBCo = @co
     	while @billmth is not null
     		begin
     		select @billnum = min(BillNumber) 
			from inserted 
			where JBCo = @co and BillMonth = @billmth
     		while @billnum is not null
            	begin

				select @chginvstat = 'N'

     			select @contract = n.Contract, @limitopt = c.JBLimitOpt,
                	@taxinterface = c.TaxInterface, @todate = n.ToDate
             	from bJBIN n with (nolock)
				join bJCCM c with (nolock) on c.JCCo = n.JBCo and c.Contract = n.Contract
              	where n.JBCo = @co and n.BillMonth = @billmth and n.BillNumber = @billnum

				if @contract is not null
					begin
	         		select @jbintotal = sum(t.AmtBilled) + 
						case @taxinterface when 'Y' then sum(t.TaxAmount) else 0 end
						case @taxinterface when 'Y' then sum(t.RetgTax) else 0 end
	         		from bJBIT t with (nolock) 
					join bJBIN n with (nolock) on n.JBCo = t.JBCo and n.BillMonth = t.BillMonth and n.BillNumber = t.BillNumber
	         		where t.JBCo = @co and t.Contract = @contract and n.InvStatus <> 'D'
						and (t.BillMonth < @billmth or (t.BillMonth = @billmth and t.BillNumber <= @billnum))
					end
    
     	        select @item = min(Item) 
				from inserted 
				where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum  
             	while @item is not null
                	begin
   -------------------------------------
                   	select @otheritem = min(Item) 
					from bJBIT with (nolock) 
					where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
                     	and Item <> @item
                	while @otheritem is not null
                    	begin

						select @otheritem = min(Item) 
						from bJBIT with (nolock)
						where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
                 		and Item <> @item and Item > @otheritem
						end
   ------------------------------------- 
				NextItem:
                 	select @item = min(Item) 
					from inserted i 
					where JBCo = @co and  BillNumber = @billnum and Item > @item
                   		and BillMonth = @billmth
     	         	if @@rowcount = 0 select @item = null
             	  	end
    
     	     	select @billnum = min(BillNumber) 
				from inserted d 
				where JBCo = @co and  BillNumber > @billnum and BillMonth = @billmth
              	if @@rowcount = 0 select @billnum = null
             	end
    
     		select @billmth = min(BillMonth) 
			from inserted d 
			where JBCo = @co and BillMonth > @billmth
     		if @@rowcount = 0 select @billmth = null
     		end
    
     	select @co = min(JBCo) 
		from inserted d 
		where JBCo > @co
      	if @@rowcount = 0 select @co = null
      	end
	end		/* End Update Loop */
*/
--------------------------------  REM'D FOR ISSUE #22126 ----------------------------------------------
    
/*Issue 13667*/
If exists(select * from inserted i join bJBCO c on i.JBCo = c.JBCo where (i.AuditYN = 'Y' and c.AuditBills = 'Y'))
    BEGIN
    If Update(Description)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIT', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Item: ' + i.Item, i.JBCo, 'C', 'Description', d.Description, i.Description, getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Item = i.Item
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where isnull(d.Description,'') <> isnull(i.Description,'')

    	and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End
    
    If Update(UnitsBilled)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIT', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Item: ' + i.Item, i.JBCo, 'C', 'UnitsBilled', convert(varchar(13), d.UnitsBilled), convert(varchar(13), i.UnitsBilled), getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Item = i.Item
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where d.UnitsBilled <> i.UnitsBilled
    	and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End
    
    If Update(AmtBilled)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIT', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Item: ' + i.Item, i.JBCo, 'C', 'AmtBilled', convert(varchar(13), d.AmtBilled), convert(varchar(13), i.AmtBilled), getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Item = i.Item
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where d.AmtBilled <> i.AmtBilled
    	and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End
    
    If Update(RetgBilled)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIT', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Item: ' + i.Item, i.JBCo, 'C', 'RetgBilled', convert(varchar(13), d.RetgBilled), convert(varchar(13), i.RetgBilled), getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Item = i.Item
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where d.RetgBilled <> i.RetgBilled
    	and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End
    
    If Update(RetgRel)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIT', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Item: ' + i.Item, i.JBCo, 'C', 'RetgRel', convert(varchar(13), d.RetgRel), convert(varchar(13), i.RetgRel), getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Item = i.Item
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where d.RetgRel <> i.RetgRel
    	and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End
    
    If Update(Discount)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIT', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Item: ' + i.Item, i.JBCo, 'C', 'Discount', convert(varchar(13), d.Discount), convert(varchar(13), i.Discount), getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Item = i.Item
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where d.Discount <> i.Discount
    	and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End
    
    If Update(TaxBasis)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIT', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Item: ' + i.Item, i.JBCo, 'C', 'TaxBasis', convert(varchar(13), d.TaxBasis), convert(varchar(13), i.TaxBasis), getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Item = i.Item
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where d.TaxBasis <> i.TaxBasis
    	and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End
    
    If Update(TaxAmount)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIT', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Item: ' + i.Item, i.JBCo, 'C', 'TaxAmount', convert(varchar(13), d.TaxAmount), convert(varchar(13), i.TaxAmount), getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Item = i.Item
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where d.TaxAmount <> i.TaxAmount
    	and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End
    
    If Update(AmountDue)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIT', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Item: ' + i.Item, i.JBCo, 'C', 'AmountDue', convert(varchar(13), d.AmountDue), convert(varchar(13), i.AmountDue), getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Item = i.Item
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where d.AmountDue <> i.AmountDue
    	and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End
    
    If Update(PrevUnits)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIT', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Item: ' + i.Item, i.JBCo, 'C', 'PrevUnits', convert(varchar(13), d.PrevUnits), convert(varchar(13), i.PrevUnits), getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Item = i.Item
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where d.PrevUnits <> i.PrevUnits
    	and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End
    
    If Update(PrevAmt)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIT', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Item: ' + i.Item, i.JBCo, 'C', 'PrevAmt', convert(varchar(13), d.PrevAmt), convert(varchar(13), i.PrevAmt), getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Item = i.Item
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where d.PrevAmt <> i.PrevAmt
    	and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End
    
    If Update(PrevRetg)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIT', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Item: ' + i.Item, i.JBCo, 'C', 'PrevRetg', convert(varchar(13), d.PrevRetg), convert(varchar(13), i.PrevRetg), getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Item = i.Item
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where d.PrevRetg <> i.PrevRetg
    	and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End
    
    If Update(PrevRetgReleased)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIT', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Item: ' + i.Item, i.JBCo, 'C', 'PrevRetgReleased', convert(varchar(13), d.PrevRetgReleased), convert(varchar(13), i.PrevRetgReleased), getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Item = i.Item
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where d.PrevRetgReleased <> i.PrevRetgReleased
    	and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End
    
    If Update(PrevTax)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIT', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Item: ' + i.Item, i.JBCo, 'C', 'PrevTax', convert(varchar(13), d.PrevTax), convert(varchar(13), i.PrevTax), getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Item = i.Item
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where d.PrevTax <> i.PrevTax
    	and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End
    
    If Update(PrevDue)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIT', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Item: ' + i.Item, i.JBCo, 'C', 'PrevDue', convert(varchar(13), d.PrevDue), convert(varchar(13), i.PrevDue), getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Item = i.Item
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where d.PrevDue <> i.PrevDue
    	and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End
    
    If Update(TaxGroup)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIT', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Item: ' + i.Item, i.JBCo, 'C', 'TaxGroup', convert(varchar(3), d.TaxGroup), convert(varchar(3), i.TaxGroup), getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Item = i.Item
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where isnull(d.TaxGroup,0) <> isnull(i.TaxGroup,0)
    	and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End
    
    If Update(TaxCode)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIT', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Item: ' + i.Item, i.JBCo, 'C', 'TaxCode', d.TaxCode, i.TaxCode, getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Item = i.Item
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where isnull(d.TaxCode,'') <> isnull(i.TaxCode,'')
    	and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End
    
    If Update(CurrContract)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIT', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Item: ' + i.Item, i.JBCo, 'C', 'CurrContract', convert(varchar(13), d.CurrContract), convert(varchar(13), i.CurrContract), getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Item = i.Item
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where d.CurrContract <> i.CurrContract
    	and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End
    
    If Update(ContractUnits)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIT', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Item: ' + i.Item, i.JBCo, 'C', 'ContractUnits', convert(varchar(13), d.ContractUnits), convert(varchar(13), i.ContractUnits), getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Item = i.Item
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where d.ContractUnits <> i.ContractUnits
    	and c.AuditBills = 'Y' and i.AuditYN = 'Y'
     	End
    
    If Update(PrevWC)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIT', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Item: ' + i.Item, i.JBCo, 'C', 'PrevWC', convert(varchar(13), d.PrevWC), convert(varchar(13), i.PrevWC), getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Item = i.Item
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where d.PrevWC <> i.PrevWC
    	and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End
    
    If Update(PrevWCUnits)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIT', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Item: ' + i.Item, i.JBCo, 'C', 'PrevWCUnits', convert(varchar(13), d.PrevWCUnits), convert(varchar(13), i.PrevWCUnits), getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Item = i.Item
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where d.PrevWCUnits <> i.PrevWCUnits
    	and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End
    
    If Update(WC)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIT', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Item: ' + i.Item, i.JBCo, 'C', 'WC', convert(varchar(13), d.WC), convert(varchar(13), i.WC), getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Item = i.Item
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where d.WC <> i.WC
    	and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End
    
    If Update(WCUnits)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIT', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Item: ' + i.Item, i.JBCo, 'C', 'WCUnits', convert(varchar(13), d.WCUnits), convert(varchar(13), i.WCUnits), getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Item = i.Item
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where d.WCUnits <> i.WCUnits
    	and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End
    
    If Update(PrevSM)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIT', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Item: ' + i.Item, i.JBCo, 'C', 'PrevSM', convert(varchar(13), d.PrevSM), convert(varchar(13), i.PrevSM), getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Item = i.Item
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where d.PrevSM <> i.PrevSM
    	and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End
    
    If Update(Installed)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIT', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Item: ' + i.Item, i.JBCo, 'C', 'Installed', convert(varchar(13), d.Installed), convert(varchar(13), i.Installed), getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Item = i.Item
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where d.Installed <> i.Installed
    	and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End
    
    If Update(Purchased)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIT', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Item: ' + i.Item, i.JBCo, 'C', 'Purchased', convert(varchar(13), d.Purchased), convert(varchar(13), i.Purchased), getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Item = i.Item
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where d.Purchased <> i.Purchased
    	and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End
    
    If Update(SM)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIT', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Item: ' + i.Item, i.JBCo, 'C', 'SM', convert(varchar(13), d.SM), convert(varchar(13), i.SM), getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Item = i.Item
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where d.SM <> i.SM
    	and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End
    
    If Update(SMRetg)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIT', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Item: ' + i.Item, i.JBCo, 'C', 'SMRetg', convert(varchar(13), d.SMRetg), convert(varchar(13), i.SMRetg), getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Item = i.Item
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where d.SMRetg <> i.SMRetg
    	and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End
    
    If Update(PrevSMRetg)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIT', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Item: ' + i.Item, i.JBCo, 'C', 'PrevSMRetg', convert(varchar(13), d.PrevSMRetg), convert(varchar(13), i.PrevSMRetg), getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Item = i.Item
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where d.PrevSMRetg <> i.PrevSMRetg
    	and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End
    
    If Update(PrevWCRetg)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIT', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Item: ' + i.Item, i.JBCo, 'C', 'PrevWCRetg', convert(varchar(13), d.PrevWCRetg), convert(varchar(13), i.PrevWCRetg), getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Item = i.Item
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where d.PrevWCRetg <> i.PrevWCRetg
    	and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End
    
    If Update(WCRetg)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIT', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Item: ' + i.Item, i.JBCo, 'C', 'WCRetg', convert(varchar(13), d.WCRetg), convert(varchar(13), i.WCRetg), getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Item = i.Item
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where d.WCRetg <> i.WCRetg
    	and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End
    
    If Update(Contract)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIT', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Item: ' + i.Item, i.JBCo, 'C', 'Contract', d.Contract, i.Contract, getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Item = i.Item
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where isnull(d.Contract,'') <> isnull(i.Contract,'')
    	and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End

    If Update(RetgTax)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIT', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Item: ' + i.Item, i.JBCo, 'C', 'RetgTax', convert(varchar(13), d.RetgTax), convert(varchar(13), i.RetgTax), getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Item = i.Item
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where d.RetgTax <> i.RetgTax
    	and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End
    
    If Update(PrevRetgTax)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIT', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Item: ' + i.Item, i.JBCo, 'C', 'PrevRetgTax', convert(varchar(13), d.PrevRetgTax), convert(varchar(13), i.PrevRetgTax), getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Item = i.Item
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where d.PrevRetgTax <> i.PrevRetgTax
    	and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End

    If Update(RetgTaxRel)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIT', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Item: ' + i.Item, i.JBCo, 'C', 'RetgTaxRel', convert(varchar(13), d.RetgTaxRel), convert(varchar(13), i.RetgTaxRel), getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Item = i.Item
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where d.RetgTaxRel <> i.RetgTaxRel
    	and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End
    
    If Update(PrevRetgTaxRel)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIT', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Item: ' + i.Item, i.JBCo, 'C', 'PrevRetgTaxRel', convert(varchar(13), d.PrevRetgTaxRel), convert(varchar(13), i.PrevRetgTaxRel), getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Item = i.Item
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where d.PrevRetgTaxRel <> i.PrevRetgTaxRel
    	and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End

    If Update(UnitsClaimed)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIT', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Item: ' + i.Item, i.JBCo, 'C', 'UnitsClaimed', convert(varchar(13), d.UnitsClaimed), convert(varchar(13), i.UnitsClaimed), getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Item = i.Item
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where d.UnitsClaimed <> i.UnitsClaimed
    	and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End

    If Update(AmtClaimed)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIT', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Item: ' + i.Item, i.JBCo, 'C', 'AmtClaimed', convert(varchar(13), d.AmtClaimed), convert(varchar(13), i.AmtClaimed), getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Item = i.Item
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where d.AmtClaimed <> i.AmtClaimed
    	and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End

    If Update(ReasonCode)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIT', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Item: ' + i.Item, i.JBCo, 'C', 'ReasonCode', convert(varchar(10), d.ReasonCode), convert(varchar(10), i.ReasonCode), getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Item = i.Item
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where isnull(d.ReasonCode, '') <> isnull(i.ReasonCode, '')
    	and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End
    END
    
return
   
error:
select @errmsg = @errmsg + ' - cannot update JB Invoice Item Totals!'

if @openotheritemcursor = 1
	begin
	close bcOtherItem
	deallocate bcOtherItem
	select @openotheritemcursor = 0
	end

if @openbJBITcursor = 1
	begin
	close bJBIT_insert
	deallocate bJBIT_insert
	select @openbJBITcursor = 0
	end

RAISERROR(@errmsg, 11, -1);
rollback transaction
   
   
  
 






GO
ALTER TABLE [dbo].[bJBIT] WITH NOCHECK ADD CONSTRAINT [CK_bJBIT_AuditYN] CHECK (([AuditYN]='Y' OR [AuditYN]='N'))
GO
ALTER TABLE [dbo].[bJBIT] WITH NOCHECK ADD CONSTRAINT [CK_bJBIT_ChangedYN] CHECK (([ChangedYN]='Y' OR [ChangedYN]='N'))
GO
ALTER TABLE [dbo].[bJBIT] WITH NOCHECK ADD CONSTRAINT [CK_bJBIT_Purge] CHECK (([Purge]='Y' OR [Purge]='N'))
GO
CREATE UNIQUE CLUSTERED INDEX [biJBIT] ON [dbo].[bJBIT] ([JBCo], [BillMonth], [BillNumber], [Item]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biJBITContractItem] ON [dbo].[bJBIT] ([JBCo], [Contract], [Item]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bJBIT] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
