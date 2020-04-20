CREATE TABLE [dbo].[bJBIL]
(
[JBCo] [dbo].[bCompany] NOT NULL,
[BillMonth] [dbo].[bMonth] NOT NULL,
[BillNumber] [int] NOT NULL,
[Line] [int] NOT NULL,
[Item] [dbo].[bContractItem] NULL,
[Contract] [dbo].[bContract] NULL,
[Job] [dbo].[bJob] NULL,
[PhaseGroup] [dbo].[bGroup] NULL,
[Phase] [dbo].[bPhase] NULL,
[Date] [dbo].[bDate] NULL,
[Template] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[TemplateSeq] [int] NULL,
[TemplateSortLevel] [tinyint] NULL,
[TemplateSeqSumOpt] [tinyint] NULL,
[TemplateSeqGroup] [int] NULL,
[LineType] [char] (1) COLLATE Latin1_General_BIN NULL,
[Description] [varchar] (128) COLLATE Latin1_General_BIN NULL,
[TaxGroup] [dbo].[bGroup] NULL,
[TaxCode] [dbo].[bTaxCode] NULL,
[MarkupOpt] [char] (1) COLLATE Latin1_General_BIN NULL,
[MarkupRate] [numeric] (17, 6) NOT NULL,
[Basis] [dbo].[bDollar] NOT NULL,
[MarkupAddl] [dbo].[bDollar] NOT NULL,
[MarkupTotal] [dbo].[bDollar] NOT NULL,
[Total] [dbo].[bDollar] NOT NULL,
[Retainage] [dbo].[bDollar] NOT NULL,
[Discount] [dbo].[bDollar] NOT NULL,
[NewLine] [int] NULL,
[ReseqYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJBIL_ReseqYN] DEFAULT ('N'),
[LineKey] [varchar] (100) COLLATE Latin1_General_BIN NULL,
[Notes] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[TemplateGroupNum] [int] NULL,
[LineForAddon] [int] NULL,
[AuditYN] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJBIL_AuditYN] DEFAULT ('Y'),
[Purge] [dbo].[bYN] NOT NULL CONSTRAINT [DF_bJBIL_Purge] DEFAULT ('N'),
[UniqueAttchID] [uniqueidentifier] NULL,
[KeyID] [bigint] NOT NULL IDENTITY(1, 1)
) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[btJBILd] ON [dbo].[bJBIL]
FOR DELETE AS

/***********************************************************************************
*	This trigger rejects delete of bJBIL
*	 if the following error condition exists:
*		none
*
*  Created by: kb 5/15/00
*  Modified by: bc 10/10/00 - added code to update JBIT whenever a JBIL record is deleted
*  		kb 9/14/1 - issue #14526
*   	kb 9/26/1 - issue #14680
*    	kb 10/10/1 - issue #14875
*   	ALLENN 11/16/2001 Issue #13667
*     	kb 11/27/1 - issue #15303
*     	kb 2/19/2 - issue #16147
*		kb 4/16/2 - issue #17006
*	  	kb 5/6/2 - issue #17006
*     	bc 5/7/2 - issue #17270
*		TJL 07/02/02 - Issue #17274,#17701, Adjust entire Addon update upon Line delete.	
*		kb 7/9/2 - update to JBIT_AmountDue 
*					should not subtract out Discount on contract bills
*					and JBIN_InvDue shouldn't subtract it out on non-contract bills
*		kb 8/5/2 - issue #18207 - changed view usage to tables
*		TJL 11/06/02 - Issue #18740, No need to update JBIN, JBIT, JBIL, JBMD when bill is purged
*		TJL 01/27/03 - Issue #20090, Total Addons do not always Update when JBIL line deleted
*		TJL 02/04/03 - Issue #20290, Place Proper values in JBIT.UnitsBilled and JBIT.WCRetPct
*		TJL 09/08/03 - Issue #22126, Speed enhancement, remove psuedo cursor
*		TJL 10/06/03 - Issue #17897, Corrected MiscDistCode references to datatype char(10) (Consistent w/AR and MS)
*		TJL 03/15/04 - Issue #24051, Correct Keystring, Converted BillMonth
*		TJL 05/10/04 - Issue #24566, Correct incorrect (convert(varchar(), ____)) statements thru-out
*		TJL 07/29/08 - Issue #128962, JB International Sales Tax
*
************************************************************************************************/
declare @errmsg varchar(255), @validcnt int, @errno int, @numrows int, @nullcnt int,
    @co bCompany, @mth bMonth, @billnum int, @line int, @seq int, @taxbasis bDollar,
    @taxamount bDollar, @item bContractItem, @addonline int, @basis bDollar, @oldamt bDollar,
    @rcode int, @template varchar(10), @tempseq int, @linekey varchar(100), @addonseq int,
    @seqtype char(1), @total bDollar, @retainage bDollar, @discount bDollar, @detaddonseq int,
    @miscamt bDollar, @linetype char(1), @custgroup bGroup, @miscdistcode char(10),
    @invdate bDate, @miscdistdesc bDesc, @phasegroup bGroup, @phase bPhase,
    @job bJob, @date bDate, @groupnum int, @totlinekey varchar(100),
    @contract bContract, @unitprice bUnitCost, @retpct bPct, @SubjectToAddon int,
    @subjectbasis bDollar, @taxgroup bGroup, @taxcode bTaxCode, @markupopt char(1),
    @taxrate bUnitCost, @markuprate bUnitCost, @tempseqgroup int, @subtotal bDollar,
    @addlmarkup bDollar, @addontype char(1), @seqdesc bDesc,
    @SubjectToTotalAddon int, @customer bCustomer, @purgeyn bYN, @openJBILcursor int,
 	--International Sales Tax
	@amtbilled bDollar, @retgtax bDollar
   
select @numrows = @@rowcount, @openJBILcursor = 0

select @rcode = 0

if @numrows = 0 return
set nocount on

declare bJBIL_delete cursor local fast_forward for
select JBCo, BillMonth, BillNumber, Line, Item, LineType, TemplateSeq,
	Template, LineKey, Total, Total, PhaseGroup, Phase, Job, Date,
	TemplateSeqGroup, Purge
from deleted
   
open bJBIL_delete
select @openJBILcursor = 1

fetch next from bJBIL_delete into @co, @mth, @billnum, @line, @item, @linetype, @tempseq,
   	@template, @linekey, @basis, @miscamt, @phasegroup, @phase, @job, @date,
   	@groupnum, @purgeyn
while @@fetch_status = 0
   	begin	/* Begin Deleted JBIL Loop */
	select @amtbilled = 0, @retainage = 0, @retgtax = 0, @taxbasis = 0, @taxamount = 0, @discount = 0	

   	select @contract = Contract, @customer = Customer, @custgroup = CustGroup,
   		@invdate = InvDate
	from bJBIN with (nolock)
   	where JBCo = @co and BillMonth = @mth and BillNumber = @billnum
   
   	/* If purge flag is set to 'Y', three conditions may exist.
   		1) If this is a single Bill being deleted by hitting 'Delete' Key
   		   then exit immediately to skip all unnecessary updates to detail
   		   records that are also being deleted.
   		2) If this is a True Purge then multiple Bills may exist in the 
   		   'delete' queue.  Again, it is OK to exit immediately since the
   		   'delete' queue will contain ONLY Bills (Detail Tables will contain
   		   ONLY records) marked for PURGE.  Therefore there is no sense in
   		   cycling through each Bill because they are ALL marked to be Purged.
   		3) Bill Lines or Detail sequences are being resequenced.  Since all values
   		   have already been established in all related tables, there is no need
   		   to perform trigger updates.  
   		****NOTE**** 
   		JB is unique in that a user is allowed to delete a bill and its detail
   		from a JB Bill Header form.  There is potential for leaving detail out
   		there if a JBIN record is removed ADHOC but user insist on this capability. */
   	if @purgeyn = 'Y' 
   		begin
   		if @openJBILcursor = 1
   			begin
   			close bJBIL_delete
   			deallocate bJBIL_delete
   			select @openJBILcursor = 0
   			end
   		return
   		end
   
   	if exists(select 1 from bJBTA with (nolock) where JBCo = @co and Template = @template
   			and Seq = @tempseq)
   		begin	
   		exec @rcode = bspJBTandMUpdateSeqAddons @co, @mth, @billnum, @line, null, null,
   			@template, @tempseq, @linekey, null, null, @item, @errmsg output
   		--if @rcode <> 0 goto error
   		end 	
   
   	update bJBID 
   	set AuditYN = 'N' 
   	where JBCo = @co and BillMonth = @mth and BillNumber = @billnum and Line = @line
   
   	delete from bJBID 
   	where JBCo = @co and BillMonth = @mth and BillNumber = @billnum and Line = @line
    
   	select @unitprice = case  when UM <> 'LS' then UnitPrice else 0 end
   	from bJCCI with (nolock)
   	where JCCo = @co and Contract = @contract and Item = @item
 	
	if @item is not null
		begin
		/* Now we need to update the JBIT record with the values from JBIL. Unlike normal trigger updates 
		   to other tables, this differs because we need values from the other lines to determine values 
		   for this line.  
		
		   The other line values might be set earlier by procedure "bspJBTandMUpdateSeqAddons" and 
		   because the procedure was called from this trigger and because it updates JBIL lines as well, 
		   those JBIL triggers get suspended and don't properly update the JBIT table when the Addons get updated.
		   This throws the JBIT values off and they are unusable. Therefore we call a procedure to update
		   JBIT values. */
		exec @rcode = vspJBTandMUpdateJBIT @co, @mth, @billnum, @contract, @item, @errmsg output
		if @rcode <> 0 goto error
  	 	end

   	/*misc dist*/
   	if @linetype = 'M'
       	begin	/* Begin LineType M Loop */
       	select @custgroup = CustGroup, @miscdistcode = MiscDistCode,
       		@miscdistdesc = Description
       	from bJBTS with (nolock)
   		where JBCo = @co and Template = @template and Seq = @tempseq
   	 
       	if @miscdistcode is not null
           	begin
           	if exists(select 1 from bJBIL with (nolock) where JBCo = @co and
				BillMonth = @mth and BillNumber = @billnum and
				Line <> @line and TemplateSeq in (select Seq from bJBTS with (nolock) 
         			where JBCo = @co and Template = @template and MiscDistCode = @miscdistcode))
   				begin
               	update bJBMD 
   				set Amt = Amt - @miscamt 
   				from bJBMD 
   				where JBCo = @co and BillMonth = @mth and BillNumber = @billnum 
   					and CustGroup = @custgroup and MiscDistCode = @miscdistcode
               	end
           	else
               	begin
               	delete from bJBMD  
   				where JBCo = @co and BillMonth = @mth
               	  	and BillNumber = @billnum and MiscDistCode = @miscdistcode
               	end
           	end

		select @total = Total, @basis = Basis
		from deleted 
   		where JBCo = @co and BillMonth = @mth and BillNumber = @billnum and Line = @line 
			and LineType = 'M'

		update bJBIL 
   		set Total =Total - @total, Basis = Basis - @basis, AuditYN = 'N'
    	from bJBIL 
   		where JBCo = @co and BillMonth = @mth and BillNumber = @billnum
        	and LineType = 'M'

		update bJBIL 
   		set AuditYN = 'Y'
    	from bJBIL 
   		where JBCo = @co and BillMonth = @mth and BillNumber = @billnum
        	and LineType = 'M'
		end		/* End LineType M Loop */

   if @contract is null
    	begin	/* Begin Non-Contract Loop */
		/* Now we need to update the JBIN record with the values from JBIL. Unlike normal trigger updates 
		   to other tables, this differs because we need values from the other lines to determine values 
		   for this line.  
		
		   The other line values might be set earlier by procedure "bspJBTandMUpdateSeqAddons" and 
		   because the procedure was called from this trigger and because it updates JBIL lines as well, 
		   those JBIL triggers get suspended and don't properly update the JBIN table when the Addons get updated.
		   This throws the JBIN values off and they are unusable. Therefore we call a procedure to update
		   JBIN values. */
		exec @rcode = vspJBTandMUpdateJBIT @co, @mth, @billnum, null, null, @errmsg output
		if @rcode <> 0 goto error
		end		/* End Non-Contract Loop */
   
   	fetch next from bJBIL_delete into @co, @mth, @billnum, @line, @item, @linetype, @tempseq,
   		@template, @linekey, @basis, @miscamt, @phasegroup, @phase, @job, @date,
   		@groupnum, @purgeyn
   	end		/* End deleted JBIL Loop */
   
if @openJBILcursor = 1
   	begin
   	close bJBIL_delete
   	deallocate bJBIL_delete
   	select @openJBILcursor = 0
   	end
--------------------------------  REM'D FOR ISSUE #22126 ----------------------------------------------
/*
select @co = min(JBCo) 
from deleted d
while @co is not null
begin
select @mth = min(BillMonth) 
from deleted d 
where JBCo = @co
while @mth is not null
   	begin
     	select @billnum = min(BillNumber) 
	from deleted d 
	where JBCo = @co and BillMonth = @mth
	while @billnum is not null
     		begin
       	select @contract = Contract, @customer = Customer, @custgroup = CustGroup
         	from bJBIN 
		where JBCo = @co and BillMonth = @mth and BillNumber = @billnum

			select @line = min(Line) 
		from deleted d 
		where JBCo = @co and BillMonth = @mth and BillNumber = @billnum
		while @line is not null
           	begin  -- Begin Line Loop
          		select @item = Item, @template = Template, @tempseq = TemplateSeq,
               	@linekey = LineKey, @basis = Total, @miscamt = Total,
               	@linetype = LineType, @phasegroup = PhaseGroup, @phase = Phase,
              		@job = Job, @date = Date, @groupnum = TemplateSeqGroup, @purgeyn = Purge
            	from deleted d 
			where JBCo = @co and BillMonth = @mth and BillNumber = @billnum and Line = @line


   				end
   
                   select @line = min(Line) from deleted d where JBCo = @co and BillMonth = @mth and
                     BillNumber = @billnum and Line > @line
              		end		--End Line Loop
   
              	select @billnum = min(BillNumber) from deleted d where JBCo = @co and BillMonth = @mth
                	and BillNumber > @billnum
          		end		-- End Bill Number Loop
   
          	select @mth = min(BillMonth) from deleted d where JBCo = @co and BillMonth > @mth
       	end		-- End Bill Month Loop
   
   	select @co = min(JBCo) from deleted d where JBCo > @co
       end		-- End Co Loop
   */
   --------------------------------  REM'D FOR ISSUE #22126 ----------------------------------------------
    
/*Issue 13667*/
Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
Select 'bJBIL', 'JBCo: ' + convert(varchar(3),d.JBCo) + 'BillMonth: ' + convert(varchar(8), d.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),d.BillNumber) + 'Line: ' + convert(varchar(10),d.Line),d.JBCo, 'D', null, null, null, getdate(), SUSER_SNAME()
From deleted d
Join bJBCO c on c.JBCo = d.JBCo
Where c.AuditBills = 'Y' and d.AuditYN = 'Y'

return

error:
select @errmsg = @errmsg + ' - cannot delete JBIL!'
   
if @openJBILcursor = 1
   	begin
   	close bJBIL_delete
   	deallocate bJBIL_delete
   	select @openJBILcursor = 0
   	end
   
RAISERROR(@errmsg, 11, -1);
rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[btJBILi] ON [dbo].[bJBIL]
FOR INSERT AS

/****************************************************************************************
*	This trigger rejects insert of bJBIL
*	if the following error condition exists:
*		none
*
*  Created by: kb 5/15/00
*  Modified by: bc 10/10/00 - added code to handle the sales tax for MarkupOpt = 'T'
*                             when inserting into JBIT
*                           - update JBIT.TaxBasis with jbil.Basis instead of jbil.total
*		bc 11/14/10 - write JBIL.Conract to JBIT
*   	kb 7/24/01 - issue 14097
*   	kb 10/10/1 issue #14875
*    	ALLENN 11/16/2001 Issue #13667
*  		kb 11/27/1 issue #15303
*    	kb 2/19/2 - issue #16147
* 		kb 4/16/2 - issue #17006
* 		kb 5/6/2 - issue #17006
*		TJL 07/03/02 - Issue #17701, Call bspJBTandMUpdateSeqAddons
*		kb 7/9/2 - update to JBIT_AmountDue 
*					should not subtract out Discount on contract bills
*					and JBIN_InvDue shouldn't subtract it out on non-contract bills
*		TJL 09/19/02 - Issue #17887, 
*					Contract Bills, JBIT.AmountDue wrong due to incorrect TaxAmount Update
*					Non-Contract Bills, JBIN.AllValues (except InvTotal) updated incorrectly.
*  		bc 09/26/02 - Issue #18719 - JBIT.TaxGroup was getting nulled out in bJBIT
*		TJL 10/17/02 - Issue #18982 - Expand on #18719, Set TaxGroup, TaxCode in bJBIT only on insert
*		TJL 10/29/02 - Issue #18907 - Add various Prev values to Insert statement to bJBIT, consistent with btJBILu
*		TJL 01/27/03 - Issue #20090, Total Addons do not always Update when JBIL line deleted
*		TJL 02/04/03 - Issue #20290, Place Proper values in JBIT.UnitsBilled and JBIT.WCRetPct (T&M Init)
*		TJL 09/08/03 - Issue #22126, Speed enhancement, remove psuedo cursor, suspend during Resequencing
*		TJL 10/06/03 - Issue #17897, Corrected MiscDistCode references to datatype char(10) (Consistent w/AR and MS)
*		TJL 03/15/04 - Issue #24051, Correct Keystring, Converted BillMonth
*		TJL 05/10/04 - Issue #24566, Correct incorrect (convert(varchar(), ____)) statements thru-out
*		TJL 09/23/04 - Issue #25622, Do not UpdateAddons by trigger if using TandMInit
*		TJL 09/30/05 - Issue #28814, TaxCode updating to JBIT when correcting missing TaxCode manually
*		TJL 07/29/08 - Issue #128962, JB International Sales Tax
*
*********************************************************************************************/
declare @errmsg varchar(255), @validcnt int, @errno int, @numrows int, @nullcnt int,
   	@co bCompany, @mth bMonth, @billnum int, @line int, @tempseq int, @item bContractItem,
   	@contract bContract, @acothrudate bDate, @msg varchar(255),
   	@basis bDollar, @addlmarkup bDollar, @taxbasis bDollar, @taxamount bDollar,
   	@total bDollar, @retainage bDollar, @discount bDollar, @linetype char(1),
   	@custgroup bGroup, @miscamt bDollar, @miscdistcode char(10),
   	@miscdistdesc bDesc, @invdate bDate, @template varchar(10),
   	@prevbillforitem_month bMonth, @prevbillforitem int, @previtemflag bYN,
   	@previtemunits bUnits, @previtemamt bDollar, @previtemretg bDollar,
   	@previtemrelretg bDollar, @previtemtax bDollar, @previtemdue bDollar,
   	@prevwc bDollar, @prevwcunits bDollar, @prevsm bDollar, @prevsmretg bDollar,
   	@prevwcretg bDollar, @itemtaxgroup bGroup, @itemtaxcode bTaxCode,
   	@procgroup varchar(20), @unitprice bUnitCost, @rcode int, @linekey varchar(100),
   	@openJBILcursor int, @purgeyn bYN, @ltaxgroup bGroup, @ltaxcode bTaxCode, @markupopt char(1),  
   	@tmupdateaddonyn char(1),
	--International Sales Tax
	@previtemretgtax bDollar, @previtemrelretgtax bDollar, @amtbilled bDollar, @retgtax bDollar
    
select @numrows = @@rowcount, @openJBILcursor = 0
    
if @numrows = 0 return
set nocount on

declare bJBIL_insert cursor local fast_forward for
select JBCo, BillMonth, BillNumber, Line, Item, LineType, TemplateSeq,
	Template, LineKey, Purge, TaxGroup, TaxCode, MarkupOpt	
from inserted
   
open bJBIL_insert
select @openJBILcursor = 1
   
fetch next from bJBIL_insert into @co, @mth, @billnum, @line, @item, @linetype, @tempseq,
   	@template, @linekey, @purgeyn, @ltaxgroup, @ltaxcode, @markupopt	
while @@fetch_status = 0
   	begin	/* Begin Inserted JBIL Loop */
	select @amtbilled = 0, @retainage = 0, @retgtax = 0, @taxbasis = 0, @taxamount = 0, @discount = 0	

	/* If purge flag is set to 'Y', one condition may exist.
		1) Bill Lines or Detail sequences are being resequenced.  Since all values
		   have already been established in all related tables, there is no need
		   to perform trigger updates.  */
	if @purgeyn = 'Y' 
		begin
		if @openJBILcursor = 1
			begin
			close bJBIL_insert
			deallocate bJBIL_insert
			select @openJBILcursor = 0
			end
		return
		end
	   
	select @contract = Contract, @acothrudate = ACOThruDate, @invdate = InvDate,
		@procgroup = ProcessGroup, @tmupdateaddonyn = TMUpdateAddonYN  
	from bJBIN with (nolock)
	where JBCo = @co and BillMonth = @mth and BillNumber = @billnum
	
	/* This line has been inserted, possibly with amounts.  Addons need 
	   to be updated before updating totals in JBIT since Retainage and Tax Addons will
	   affect this line items amounts */
	if exists(select 1 from bJBTA with (nolock) where JBCo = @co and Template = @template
			and Seq = @tempseq) and @tmupdateaddonyn = 'Y'	-- and @total <> 0
		begin	
		/* This gets skipped if here as a result of running JB T&M Bill Initialization */
		exec @rcode = bspJBTandMUpdateSeqAddons @co, @mth, @billnum, @line, null, null,
			@template, @tempseq, @linekey, null, null, null, @errmsg output
		--if @rcode <> 0 goto error
		end 

	if @item is not null
		begin	/* Begin Item Not Null */
		select @itemtaxgroup = TaxGroup, @itemtaxcode = TaxCode,
			@unitprice = case when UM <> 'LS' then UnitPrice else 0 end
		from bJCCI with (nolock)
		where JCCo = @co and Contract = @contract and Item = @item

   		if exists(select 1 from JCCI with (nolock) where JCCo = @co and Contract = @contract
				  and Item = @item and BillType = 'B')
       		begin
			/*get previous bill for this item*/
       		select @prevbillforitem_month = max(t.BillMonth)
			from bJBIT t with (nolock)
			join bJBIN n with (nolock) on t.JBCo = n.JBCo and t.BillNumber = n.BillNumber
           		and t.BillMonth = n.BillMonth	
			where t.JBCo = @co and n.Contract = @contract and Item = @item
           		and InvStatus <>'D'
				and ((ProcessGroup  = @procgroup) 
					or (@procgroup is null and ProcessGroup is null))
				and ((t.BillMonth < @mth) 
					or (t.BillMonth = @mth and t.BillNumber < @billnum))
	    
			if @prevbillforitem_month is not null
				begin
         		select @prevbillforitem = max(t.BillNumber)
       			from bJBIT t with (nolock)
         		join bJBIN n with (nolock) on t.JBCo = n.JBCo and t.BillNumber = n.BillNumber and t.BillMonth = n.BillMonth
        		where t.JBCo = @co and n.Contract = @contract  and Item = @item and InvStatus <> 'D'
              		and ((ProcessGroup  = @procgroup)
              			or (@procgroup is null and ProcessGroup is null)) 
					and	t.BillMonth = @prevbillforitem_month 
					and ((t.BillMonth < @mth) or (t.BillMonth = @mth and t.BillNumber < @billnum))
	    
          		if @prevbillforitem is not null
            		begin
            		select @previtemflag = 'Y'
    	    		select @previtemunits = PrevWCUnits + WCUnits,
    	           		@previtemamt = PrevWC + WC + PrevSM + SM,
          				@previtemretg  = PrevWCRetg + WCRetg + PrevSMRetg + SMRetg + PrevRetgTax + RetgTax,
						@previtemretgtax = PrevRetgTax + RetgTax,
						@previtemrelretg = PrevRetgReleased + RetgRel,
						@previtemrelretgtax = PrevRetgTaxRel + RetgTaxRel,
    	           		@previtemtax = PrevTax + TaxAmount, @previtemdue = PrevDue + AmountDue,
    	           		@prevwc = PrevWC + WC, @prevwcunits = PrevWCUnits + WCUnits, @prevsm = PrevSM + SM,
    	           		@prevsmretg = PrevSMRetg + SMRetg, @prevwcretg = PrevWCRetg + WCRetg
    	    		from bJBIT with (nolock)
            		where JBCo = @co and BillMonth = @prevbillforitem_month and BillNumber = @prevbillforitem and Item = @item
    	    		end
         		end
			end
	   
		if not exists(select 1 from bJBIT with (nolock) where JBCo = @co and
                       		BillMonth = @mth and BillNumber = @billnum and Item = @item)
			begin
			/* Issue #17887, I am not sure this insert will ever take place since JBIL insert
			   trigger will always insert the initial JBIT record when the first
			   JBIL line is inserted.  To my thinking, the only time this will occur is if 
			   the JBIT record gets deleted and the associated JBIL records remain.  In such
			   a case, if one of the remaining JBIL records were changed then it would be necessary 
			   to re-insert the JBIT record initially.  However, I am modifying this in order to 
			   follow up the insert with an update to refresh the JBIT record with accumulated 
			   values for all existing JBIL lines at the time.*/
  			insert bJBIT (JBCo, BillMonth, BillNumber, Item, Description,
				UnitsBilled, AmtBilled, RetgBilled, RetgTax, RetgRel, RetgTaxRel, Discount, TaxBasis,
				TaxAmount, AmountDue, PrevUnits, PrevAmt,
				PrevRetg, PrevRetgTax, PrevRetgReleased, PrevRetgTaxRel,
				PrevTax, PrevDue, TaxGroup, TaxCode, CurrContract, ContractUnits,
				PrevWC, PrevWCUnits, WC, WCUnits, PrevSM, Installed, Purchased,
				SM, SMRetg, PrevSMRetg, PrevWCRetg, WCRetg, WCRetPct,
				Purge, AuditYN, Contract)
  			select i.JBCo, i.BillMonth, i.BillNumber, i.Item, j.Description,
				0, 0, 0, 0, 0, 0, 0, 0, 0, 0, isnull(@previtemunits,0), isnull(@previtemamt,0),
				isnull(@previtemretg,0), isnull(@previtemretgtax,0), isnull(@previtemrelretg,0), isnull(@previtemrelretgtax,0),
				isnull(@previtemtax,0), isnull(@previtemdue,0),
				@itemtaxgroup, @itemtaxcode, ContractAmt, ContractUnits,
				isnull(@prevwc,0), isnull(@prevwcunits,0), 0, 0, isnull(@prevsm,0), 0, 0,
 				0, 0, isnull(@prevsmretg,0), isnull(@prevwcretg,0), 0, 0,
				'N', 'N', i.Contract
			from inserted i 
			join bJCCI j on j.JCCo = i.JBCo and j.Contract = i.Contract and j.Item = i.Item
			where JBCo = @co and BillMonth = @mth and BillNumber = @billnum
            			and i.Item = @item and Line = @line

			update bJBIT 
			set AuditYN = 'Y' 
			where JBCo = @co and BillMonth = @mth and BillNumber = @billnum and Item = @item

			end

		/* We might now be dealing with new Tax Line and so update JBIT with Lines TaxGroup and TaxCode values */
		if @markupopt in ('T', 'X')
			and ((select TaxCode from bJBIT with (nolock) 
					where JBCo = @co and BillMonth = @mth and BillNumber = @billnum and Item = @item) is null
				or (select TaxGroup from bJBIT 
					where JBCo = @co and BillMonth = @mth and BillNumber = @billnum and Item = @item) is null)
			begin
			update bJBIT
			set TaxGroup = @ltaxgroup, TaxCode = @ltaxcode,	AuditYN = 'N'
			where JBCo = @co and BillMonth = @mth and BillNumber = @billnum and Item = @item

			update bJBIT 
			set AuditYN = 'Y' 
			where JBCo = @co and BillMonth = @mth and BillNumber = @billnum and Item = @item
			end

		if @tmupdateaddonyn = 'Y'
			/* This gets skipped if here as a result of running JB T&M Bill Initialization */
			begin
			/* Now we need to update the JBIT record with the values from JBIL. Unlike normal trigger updates 
			   to other tables, this differs because we need values from the other lines to determine values 
			   for this line.  
			
			   The other line values might be set earlier by procedure "bspJBTandMUpdateSeqAddons" and 
			   because the procedure was called from this trigger and because it updates JBIL lines as well, 
			   those JBIL triggers get suspended and don't properly update the JBIT table when the Addons get updated.
			   This throws the JBIT values off and they are unusable. Therefore we call a procedure to update
			   JBIT values. */
			exec @rcode = vspJBTandMUpdateJBIT @co, @mth, @billnum, @contract, @item, @msg output
  			if @rcode <> 0 goto error
			end

 		/*add change orders*/
		if @contract is not null
   			begin
     		if exists(select 1 from bJCCI with (nolock) where JCCo = @co and Contract = @contract
				and Item = @item and BillType = 'B')
         		begin
         		exec bspJBChangeOrderAdd @co, @mth, @billnum, @contract, @acothrudate, @item, @msg output
          		end
      		end
		end		/* End Item Not Null */
	    
	/*misc dist*/
	/* REM'd Issue #17897, Design decisions were made not to create JBIL entries for 'M' LineTypes
	   and not to update JBMD values as small manual changes occur.  Customers use MiscDistCodes
	   differently and continuous updates may not be appropriate.  Could be added in later once
	   we clearly establish what is required. */
	/*
	if @linetype = 'M'
		begin	
 		select @custgroup = CustGroup, @miscdistcode = MiscDistCode,
			@miscdistdesc = Description
 		from bJBTS with (nolock)
		where JBCo = @co and Template = @template and Seq = @tempseq

   		if @miscdistcode is not null
       		begin
			--select @invdate = InvDate 
			--from bJBIN with (nolock)
			--where JBCo = @co and BillMonth = @mth and BillNumber = @billnum

			select @miscamt = sum(Total) 
			from bJBIL l with (nolock)
			join bJBTS s with (nolock) on s.JBCo = l.JBCo and s.Template = l.Template 
				and s.Seq = l.TemplateSeq 
			where l.JBCo = @co and l.BillMonth = @mth and l.BillNumber = @billnum
           		and s.MiscDistCode = @miscdistcode

			update bJBMD 
			set Amt = @miscamt 
			from bJBMD 
			where JBCo = @co and BillMonth = @mth and BillNumber = @billnum 
				and CustGroup = @custgroup and MiscDistCode = @miscdistcode
     		if @@rowcount = 0
        		begin
         		insert bJBMD (JBCo, BillMonth, BillNumber, CustGroup,
            		MiscDistCode, DistDate, Description, Amt)
         		select @co, @mth, @billnum, @custgroup,
             		@miscdistcode, @invdate, @miscdistdesc, @miscamt
          		end
     		end
		end		
			*/
	   
	update bJBIL 
	set LineForAddon = @line, AuditYN = 'N'
	from inserted i 
	join bJBIL l on i.JBCo = l.JBCo and i.BillMonth = l.BillMonth and i.BillNumber = l.BillNumber
   		and i.Line = l.Line 
	where i.JBCo = @co and i.BillMonth = @mth and i.BillNumber = @billnum 
		and i.Line = @line and i.LineType = 'S'
	    
	update bJBIL 
	set AuditYN = 'Y'
	from inserted i 
	join bJBIL l on i.JBCo = l.JBCo and i.BillMonth = l.BillMonth 
		and i.BillNumber = l.BillNumber and i.Line = l.Line 
	where i.JBCo = @co and i.BillMonth = @mth and i.BillNumber = @billnum 
		and i.Line = @line and i.LineType = 'S'
	    
	/*Begin Non-Contract Updates directly to bJBIN */
	if @contract is null
   		begin	/* Begin Non-Contract Loop */
		if @tmupdateaddonyn = 'Y'
			/* This gets skipped if here as a result of running JB T&M Bill Initialization */
			begin
			/* Now we need to update the JBIN record with the values from JBIL. Unlike normal trigger updates 
			   to other tables, this differs because we need values from the other lines to determine values 
			   for this line.  
			
			   The other line values might be set earlier by procedure "bspJBTandMUpdateSeqAddons" and 
			   because the procedure was called from this trigger and because it updates JBIL lines as well, 
			   those JBIL triggers get suspended and don't properly update the JBIN table when the Addons get updated.
			   This throws the JBIN values off and they are unusable. Therefore we call a procedure to update
			   JBIN values. */
			exec @rcode = vspJBTandMUpdateJBIT @co, @mth, @billnum, null, null, @msg output
  			if @rcode <> 0 goto error
			end
		end		/* End Non-Contract Loop */
   
   	fetch next from bJBIL_insert into @co, @mth, @billnum, @line, @item, @linetype, @tempseq,
   		@template, @linekey, @purgeyn, @ltaxgroup, @ltaxcode, @markupopt
   	end		/* End Inserted JBIL Loop */
   
if @openJBILcursor = 1
   	begin
   	close bJBIL_insert
   	deallocate bJBIL_insert
   	select @openJBILcursor = 0
   	end
   
--------------------------------  REM'D FOR ISSUE #22126 ----------------------------------------------
/*
select @co = min(JBCo) 
from inserted i
while @co is not null
begin
select @hqtaxgrp = TaxGroup
from bHQCO
where HQCo = @co

select @mth = min(BillMonth) 
from inserted i 
where JBCo = @co
while @mth is not null
   	begin
   	select @billnum = min(BillNumber) 
	from inserted i 
	where JBCo = @co and BillMonth = @mth
    	while @billnum is not null
       	begin
        	select @contract = Contract 
		from bJBIN 
		where JBCo = @co and BillMonth = @mth and BillNumber = @billnum

		select @line = min(Line) 
		from inserted i 
		where JBCo = @co and BillMonth = @mth and BillNumber = @billnum
       	while @line is not null
           	begin
          		select @item = Item, @linetype = LineType, @tempseq = TemplateSeq,
               	@template = Template, @linekey = LineKey
            	from inserted i 
			where JBCo = @co and BillMonth = @mth and BillNumber = @billnum and Line = @line

            	if @item is not null
             		begin

				end

            	select @line = min(Line) 
			from inserted i 
			where JBCo = @co and BillMonth = @mth and BillNumber = @billnum 
				and Line > @line
            	end

			select @billnum = min(BillNumber) 
		from inserted i 
		where JBCo = @co and BillMonth = @mth and BillNumber > @billnum
          	end

    	select @mth = min(BillMonth) 
	from inserted i 
	where JBCo = @co and BillMonth > @mth
    	end

	select @co = min(JBCo) 
from inserted i 
where JBCo > @co
end
*/
--------------------------------  REM'D FOR ISSUE #22126 ----------------------------------------------
    
/*Issue 13667*/
Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
Select 'bJBIL', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line),i.JBCo, 'A', null, null, null, getdate(), SUSER_SNAME()
From inserted i
Join bJBCO c on c.JBCo = i.JBCo
Where c.AuditBills = 'Y' and i.AuditYN = 'Y'

return

error:
select @errmsg = @errmsg + ' - cannot insert JBIL!'

if @openJBILcursor = 1
	begin
	close bJBIL_insert
	deallocate bJBIL_insert
	select @openJBILcursor = 0
	end

RAISERROR(@errmsg, 11, -1);
rollback transaction
   
   
   
  
 



GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE TRIGGER [dbo].[btJBILu] ON [dbo].[bJBIL]
FOR UPDATE AS
   
/**************************************************************
*	This trigger rejects update of bJBIL
*	 if the following error condition exists:
*		none
*
*  Created by: kb 8/1/00
*  Modified by: bc 10/10/00 - added code to handle sales tax when MarkupOpt = 'T'
*                             when updating JBIT
* 		bc 11/14/00 - write JBIL.Contract to JBIT
*  		kb 1/11/01 - issue #11619
*     	kb 6/4/1 issue #12332
*    	kb 6/4/1 issue #14680
*     	kb 10/10/1 issue #14875
*    	ALLENN 11/16/2001 Issue #13667
*    	kb 11/27/1 - issue #15303
*     	kb 2/19/2 - issue #16147
*		kb 4/16/2 - issue #17006
*     	kb 5/1/2 - issue #17095		
*		kb 7/9/2 - update to JBIT_AmountDue 
*					should not subtract out Discount on contract bills
*					and JBIN_InvDue shouldn't subtract it out on non-contract bills
*		TJL 09/19/02 - Issue #17887, 
*					Contract Bills, follow up JBIT insert with update (See Explain below)
*					Non-Contract Bills, JBIN.AllValues (except InvTotal) updated incorrectly.
*   	bc 09/26/02 - Issue #18719 JBIT.TaxGroup was getting nulled out occassionaly.
*		TJL 10/17/02 - Issue #18982 - Expand on #18719, Set TaxGroup, TaxCode in bJBIT only on insert
*		TJL 11/06/02 - Issue #18740, Exit if (Purge) Column is updated
*		TJL 01/27/03 - Issue #20090, Total Addons do not always Update when JBIL line deleted
*		TJL 02/04/03 - Issue #20290, Place Proper values in JBIT.UnitsBilled and JBIT.WCRetPct (T&M Init)
*		RBT 08/05/03 - Issue #22019, Convert bDollar and bUnits to varchar(13) in auditing.
*		TJL 09/08/03 - Issue #22126, Speed enhancement, remove psuedo cursor
*		TJL 10/06/03 - Issue #17897, Corrected MiscDistCode references to datatype char(10) (Consistent w/AR and MS)
*		TJL 03/15/04 - Issue #24051, Correct Keystring, Converted BillMonth
*		TJL 05/10/04 - Issue #24566, Correct incorrect (convert(varchar(), ____)) statements thru-out
*		TJL 09/23/04 - Issue #25622, Do not UpdateAddons by trigger if using TandMInit
*		TJL 09/30/05 - Issue #28814, TaxCode updating to JBIT when correcting missing TaxCode manually
*		TJL 09/07/06 - Issue #122413, Fix update JBIT AmountDue to AmountDue = @amtbilled - @retainage + t.RetgRel,
*		TJL 07/29/08 - Issue #128962, JB International Sales Tax
*
**************************************************************/
declare @errmsg varchar(255), @validcnt int, @errno int, @numrows int, @nullcnt int,
	@co bCompany, @mth bMonth, @billnum int, @line int, @seq int, @item bContractItem,
	@total bDollar, @contract bContract, @acothrudate bDate, @oldamt bDollar,
	@newamt bDollar, @rcode int, @taxbasis bDollar, @taxamount bDollar, @template varchar(10),
	@tempseq int, @linekey varchar(100), @retainage bDollar, @discount bDollar,
	@invdate bDate, @custgroup bGroup, @miscdistcode char(10), @linetype char(1),
	@miscdistdesc bDesc, @miscamt bDollar,
	@prevbillforitem_month bMonth, @prevbillforitem int, @previtemflag bYN,
	@previtemunits bUnits, @previtemamt bDollar, @previtemretg bDollar,
	@previtemrelretg bDollar, @previtemtax bDollar, @previtemdue bDollar,
	@prevwc bDollar, @prevwcunits bDollar, @prevsm bDollar, @prevsmretg bDollar,
	@prevwcretg bDollar, @procgroup varchar(20), @unitprice bUnitCost,
	@miscdistseq int, @miscdistline char(10), @miscdistrate bRate, @jbidunits bUnits,
	@itemtaxgroup bGroup, @itemtaxcode bTaxCode, @openJBILcursor int, @ltaxgroup bGroup, @ltaxcode bTaxCode, @markupopt char(1),
   	@tmupdateaddonyn char(1),
	--International Sales Tax
	@previtemretgtax bDollar, @previtemrelretgtax bDollar, @amtbilled bDollar, @retgtax bDollar
     
select @numrows = @@rowcount, @openJBILcursor = 0
 
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
     
If Update(Line)
   	Begin
   	select @errmsg = 'Cannot change Line'
   	GoTo error
   	End
     
select @rcode = 0
     
if update(Item) or update(Contract) or update(Job) or update(PhaseGroup)
	or update(Phase) or update(Date) or update(Template) or update(TemplateSeq)
	or update(TemplateSortLevel) or update(TemplateSeqSumOpt)
	or update(TemplateSeqGroup) or update(LineType) or update(Description)
	or update(TaxGroup) or update(TaxCode) or update(MarkupOpt)
	or update(MarkupRate) or update(Basis) or update(MarkupAddl)
	or update(MarkupTotal) or update(Total) or update(Retainage)
	or update(Discount)
   	begin	/* Begin "If Update" Loop */
   	declare bJBIL_insert cursor local fast_forward for
   	select JBCo, BillMonth, BillNumber, Line, Item, LineType, TemplateSeq,
   		Template, LineKey, TaxGroup, TaxCode, MarkupOpt
   	from inserted
   	
   	open bJBIL_insert
   	select @openJBILcursor = 1
   	
   	fetch next from bJBIL_insert into @co, @mth, @billnum, @line, @item, @linetype, @tempseq,
   		@template, @linekey, @ltaxgroup, @ltaxcode, @markupopt
   	while @@fetch_status = 0
   		begin	/* Begin Inserted JBIL Loop */
		select @amtbilled = 0, @retainage = 0, @retgtax = 0, @taxbasis = 0, @taxamount = 0,
			@discount = 0
   
   	 	select @contract = Contract, @acothrudate = ACOThruDate, @invdate = InvDate,
   			@procgroup = ProcessGroup, @tmupdateaddonyn = TMUpdateAddonYN 
   		from bJBIN with (nolock)
   		where JBCo = @co and BillMonth = @mth and BillNumber = @billnum
   
      	if @linetype <> 'M'
        	begin	/* Begin LineType Not M Loop */
         	/*update addons for this line with new amts*/
         	if update(Total) or update(Basis)
             	begin		/* Begin Lessor Update Loop */
             	select @oldamt = isnull(d.Total,0), @newamt = isnull(i.Total,0) 
				from inserted i 
				join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber
               		and d.Line = i.Line 
				where i.JBCo = @co and i.BillMonth = @mth and i.BillNumber = @billnum and i.Line = @line
     
   				select @jbidunits = sum(Units) 
   				from bJBID with (nolock) 
   				where JBCo = @co and BillMonth = @mth and BillNumber = @billnum and Line = @line
     
   				/* This line has changed, therefore update Addons using changed basis amount.  Addons need 
				   to be updated before updating totals in JBIT since Retainage and Tax Addons will
				   affect this line items amounts */
   				if @tmupdateaddonyn = 'Y'
   					begin
					/* This gets skipped if here as a result of run JB T&M Bill Initialization */
   	          		exec @rcode = bspJBTandMUpdateSeqAddons @co,  @mth, @billnum, @line,
   	             		@oldamt, @newamt, @template, @tempseq, @linekey, 0, 0, null, @errmsg output
            			--  if @rcode<> 0  goto error
   					end
   
   				/* This line has changed, therefore update MiscDistLines using changed basis amount. */
				select @miscdistline = min(Line) 
   				from bJBIL with (nolock)
   				where JBCo = @co and BillMonth = @mth and BillNumber = @billnum and LineType = 'M'
   
   				while @miscdistline is not null
                   	begin	/* Begin MiscDistLine Loop */
					select @miscdistseq = TemplateSeq 
   					from bJBIL with (nolock)
   					where JBCo = @co and BillMonth = @mth and BillNumber = @billnum and Line = @miscdistline
     
                   	select @miscdistcode = MiscDistCode, @custgroup = CustGroup 
					from bJBTS with (nolock)
					where JBCo = @co and Template = @template and Seq = @miscdistseq
 
            		select @miscdistrate = Rate 
					from bARMC with (nolock)
					where CustGroup = @custgroup and MiscDistCode = @miscdistcode
     
                   	update bJBIL 
   					set Basis = Basis - @oldamt + @newamt,
                          	Total = Total - (@oldamt*@miscdistrate) + (@newamt*@miscdistrate), AuditYN = 'N'
					from bJBIL 
   					where JBCo = @co and BillMonth = @mth and BillNumber = @billnum	and Line = @miscdistline
    
					update bJBIL 
   					set AuditYN = 'Y'
					from bJBIL 
   					where JBCo = @co and BillMonth = @mth and BillNumber = @billnum	and Line = @miscdistline
   
   					/* Get totals for MiscDistributions and Update bJBMD for this MiscDistCode. */  
                   	select @total = isnull(sum(Total),0) 
    				from bJBIL with (nolock)
   					where JBCo = @co and BillMonth = @mth and BillNumber = @billnum and	LineType = 'M'
     
					update bJBMD 
   					set Amt = @total * @miscdistrate
					from bJBMD 
   					where JBCo = @co and BillMonth = @mth and BillNumber = @billnum and MiscDistCode = @miscdistcode
   
   					/* Get next MiscDistLine / Code */ 
					select @miscdistline = min(Line) 
   					from bJBIL with (nolock)
   					where JBCo = @co and BillMonth = @mth and BillNumber = @billnum and LineType = 'M' and Line > @miscdistline
    
					end		/* End MisDistLine Loop */
				end		/* End Lessor Update Loop */
    
			if @item is not null	-- Still LineType <> M
               	begin	/* Begin Item Not Null Loop */
   				select @itemtaxgroup = TaxGroup, @itemtaxcode = TaxCode,
   					@unitprice = case when UM <> 'LS' then UnitPrice else 0 end
   				from bJCCI with (nolock)
   				where JCCo = @co and Contract = @contract and Item = @item
    
    			if exists(select 1 from bJCCI with (nolock) where JCCo = @co and Contract = @contract
                     	and Item = @item and BillType = 'B')
                   	begin	/* Begin Get Previous and Add ChangeOrder Loop */
                   	/*get previous bill for this item*/
   					select @prevbillforitem_month = max(t.BillMonth)
					from bJBIT t with (nolock)
					join bJBIN n with (nolock) on t.JBCo = n.JBCo and t.BillNumber = n.BillNumber and t.BillMonth = n.BillMonth	
   					where t.JBCo = @co and n.Contract = @contract and Item = @item
   						and InvStatus <>'D' and ((ProcessGroup  = @procgroup) 
   							or (@procgroup is null and ProcessGroup is null))
                       	and ((t.BillMonth < @mth) 
   							or (t.BillMonth = @mth and t.BillNumber < @billnum))
     
					if @prevbillforitem_month is not null
                       	begin
                    	select @prevbillforitem = max(t.BillNumber)
                    	from bJBIT t with (nolock)
                     	join bJBIN n with (nolock) on t.JBCo = n.JBCo and t.BillNumber = n.BillNumber and t.BillMonth = n.BillMonth
                       	where t.JBCo = @co and n.Contract = @contract  and Item = @item and InvStatus <> 'D'
                           	and ((ProcessGroup  = @procgroup)
                               	or (@procgroup is null and ProcessGroup is null)) 
    							and	t.BillMonth = @prevbillforitem_month 
    							and ((t.BillMonth < @mth) or (t.BillMonth = @mth and t.BillNumber < @billnum))
     
                       	if @prevbillforitem is not null
                           	begin
                          	select @previtemunits = PrevWCUnits + WCUnits,
     	           				@previtemamt = PrevWC + WC + PrevSM + SM,
                  	           	@previtemretg  = PrevWCRetg + WCRetg + PrevSMRetg + SMRetg + PrevRetgTax + RetgTax,
								@previtemretgtax = PrevRetgTax + RetgTax,
                              	@previtemrelretg = PrevRetgReleased + RetgRel,
								@previtemrelretgtax = PrevRetgTaxRel + RetgTaxRel,
                  	           	@previtemtax = PrevTax + TaxAmount, @previtemdue = PrevDue + AmountDue,
                  	           	@prevwc = PrevWC + WC, @prevwcunits = PrevWCUnits + WCUnits, @prevsm = PrevSM + SM,
        	           			@prevsmretg = PrevSMRetg + SMRetg, @prevwcretg = PrevWCRetg + WCRetg
                  	    	from bJBIT with (nolock)
                          	where JBCo = @co and BillMonth = @prevbillforitem_month and BillNumber = @prevbillforitem and Item = @item
                  	    	end
						end
   
   					exec bspJBChangeOrderAdd @co, @mth, @billnum, @contract, @acothrudate, @item, @errmsg output
					end		/* End Get Previous and Add ChangeOrder Loop */
    
   				-- REM'd Issue #22126, established earlier
               	--select @contract = Contract, @item = Item 
   				--from bJBIL 
   				--where JBCo = @co and BillMonth = @mth and BillNumber = @billnum and Line = @line
    
   				/****************** BEGIN UPDATING bJBIT FOR THIS ITEM ********************/
   				/* Update bJBIT for this Item, for this JBIL line value that has changed. */
              	if not exists(select 1 from bJBIT with (nolock) where JBCo = @co and
                		BillMonth = @mth and BillNumber = @billnum and Item = @item)
					begin	/* Begin bJBIT Loop */
   					/* Issue #17887, I am not sure this insert will ever take place since JBIL insert
   					   trigger will always insert the initial JBIT record when the first
   					   JBIL line is inserted.  To my thinking, the only time this will occur is if 
   					   the JBIT record gets deleted and the associated JBIL records remain.  In such
   					   a case, if one of the remaining JBIL records were changed then it would be necessary 
   					   to re-insert the JBIT record initially. */
                  	insert bJBIT (JBCo, BillMonth, BillNumber, Item, Description,
                    	UnitsBilled, AmtBilled, RetgBilled, RetgTax, RetgRel, RetgTaxRel, Discount, TaxBasis,
                    	TaxAmount, AmountDue, PrevUnits, PrevAmt,
                    	PrevRetg, PrevRetgTax, PrevRetgReleased, PrevRetgTaxRel,
                    	PrevTax, PrevDue, TaxGroup, TaxCode, CurrContract, ContractUnits,
                    	PrevWC, PrevWCUnits, WC, WCUnits, PrevSM, Installed, Purchased,
                    	SM, SMRetg, PrevSMRetg, PrevWCRetg, WCRetg, WCRetPct,
                    	Purge, AuditYN, Contract)
                  	select i.JBCo, i.BillMonth, i.BillNumber, i.Item, j.Description,
                    	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, isnull(@previtemunits,0), isnull(@previtemamt,0),
                    	isnull(@previtemretg,0), isnull(@previtemretgtax,0), isnull(@previtemrelretg,0), isnull(@previtemrelretgtax,0),
                    	isnull(@previtemtax,0), isnull(@previtemdue,0),
                    	@itemtaxgroup, @itemtaxcode, ContractAmt, ContractUnits,
       					isnull(@prevwc,0), isnull(@prevwcunits,0), 0, 0, isnull(@prevsm,0), 0, 0,
                 		0, 0, isnull(@prevsmretg,0), isnull(@prevwcretg,0), 0, 0,
                    	'N', 'N', i.Contract
                	from inserted i 
					join bJCCI j on j.JCCo = i.JBCo and j.Contract = i.Contract and j.Item = i.Item
					where JBCo = @co and BillMonth = @mth and BillNumber = @billnum
                    	and i.Item = @item and Line = @line
    
					update bJBIT 
   					set AuditYN = 'Y' 
   					where JBCo = @co and BillMonth = @mth and BillNumber = @billnum and Item = @item
   
   					end		/* End bJBIT Loop */
  
				/* We might now be dealing with a Tax Line and so update JBIT with Lines TaxCode values */
				if @markupopt in ('T', 'X')
					and ((select TaxCode from bJBIT with (nolock) 
							where JBCo = @co and BillMonth = @mth and BillNumber = @billnum and Item = @item) is null
						or (select TaxGroup from bJBIT 
							where JBCo = @co and BillMonth = @mth and BillNumber = @billnum and Item = @item) is null)
					begin
					update bJBIT
					set TaxGroup = @ltaxgroup, TaxCode = @ltaxcode,	AuditYN = 'N'
					where JBCo = @co and BillMonth = @mth and BillNumber = @billnum and Item = @item

					update bJBIT 
					set AuditYN = 'Y' 
					where JBCo = @co and BillMonth = @mth and BillNumber = @billnum and Item = @item
					end

				if @tmupdateaddonyn = 'Y'
					/* This gets skipped if here as a result of running JB T&M Bill Initialization */
					begin
					/* Now we need to update the JBIT record with the values from JBIL. Unlike normal trigger updates 
					   to other tables, this differs because we need values from the other lines to determine values 
					   for this line.  
					
					   The other line values might be set earlier by procedure "bspJBTandMUpdateSeqAddons" and 
					   because the procedure was called from this trigger and because it updates JBIL lines as well, 
					   those JBIL triggers get suspended and don't properly update the JBIT table when the Addons get updated.
					   This throws the JBIT values off and they are unusable. Therefore we call a procedure to update
					   JBIT values. */
					exec @rcode = vspJBTandMUpdateJBIT @co, @mth, @billnum, @contract, @item, @errmsg output
  					if @rcode <> 0 goto error
					end
   				/****************** END UPDATING bJBIT FOR THIS ITEM ********************/
           		end		/* End Item Not Null Loop */
   			end		/* End LineType Not M Loop */
   
   		/* REM'd Issue #17897, Design decisions were made not to create JBIL entries for 'M' LineTypes
   	   	   and not to update JBMD values as small manual changes occur.  Customers use MiscDistCodes
   	   	   differently and continuous updates may not be appropriate.  Could be added in later once
   	   	   we clearly establish what is required. */
   		/*
		if @linetype = 'M'
           	begin	
			select @custgroup = CustGroup, @miscdistcode = MiscDistCode,
				@miscdistdesc = Description
			from bJBTS with (nolock)
   			where JBCo = @co and Template = @template and Seq = @tempseq
			if @miscdistcode is not null
               	begin	
				select @miscamt = sum(Total) 
   				from bJBIL l with (nolock)
   				where l.JBCo = @co and l.BillMonth = @mth and l.BillNumber = @billnum
					and MarkupOpt <> 'T'
					-- and s.MiscDistCode = @miscdistcode
   
   				-- REM'd Issue #22126, established earlier 
				--select @invdate = InvDate 
   				--from bJBIN with (nolock)
   				--where JBCo = @co and BillMonth = @mth and BillNumber = @billnum
    			
   				update bJBMD 
   				set Amt = @miscamt 
   				from bJBMD 
   				where JBCo = @co and BillMonth = @mth and BillNumber = @billnum 
   					and CustGroup = @custgroup and MiscDistCode = @miscdistcode
   	  			if @@rowcount = 0
   	             	begin
   	              	insert bJBMD (JBCo, BillMonth, BillNumber, CustGroup,
   	                  	MiscDistCode, DistDate, Description, Amt)
   	               	select @co, @mth, @billnum, @custgroup,
   	                 	@miscdistcode, @invdate, @miscdistdesc, @miscamt
   	               	end		
				end		
   			end		
   			*/
    
		if @contract is null
           	begin	/* Begin Non-Contract Loop */
			if @tmupdateaddonyn = 'Y'
				/* This gets skipped if here as a result of running JB T&M Bill Initialization */
				begin
				/* Now we need to update the JBIN record with the values from JBIL. Unlike normal trigger updates 
				   to other tables, this differs because we need values from the other lines to determine values 
				   for this line.  
				
				   The other line values might be set earlier by procedure "bspJBTandMUpdateSeqAddons" and 
				   because the procedure was called from this trigger and because it updates JBIL lines as well, 
				   those JBIL triggers get suspended and don't properly update the JBIN table when the Addons get updated.
				   This throws the JBIN values off and they are unusable. Therefore we call a procedure to update
				   JBIN values. */
				exec @rcode = vspJBTandMUpdateJBIT @co, @mth, @billnum, null, null, @errmsg output
  				if @rcode <> 0 goto error
				end
   			end		/* End Non-Contract Loop */
   
   		fetch next from bJBIL_insert into @co, @mth, @billnum, @line, @item, @linetype, @tempseq,
   			@template, @linekey, @ltaxgroup, @ltaxcode, @markupopt
   		end		/* End Inserted JBIL Loop */
   
   	if @openJBILcursor = 1
   		begin
   		close bJBIL_insert
   		deallocate bJBIL_insert
   		select @openJBILcursor = 0
   		end
   
   	end		/* Begin "If Update" Loop */
   
   --------------------------------  REM'D FOR ISSUE #22126 ----------------------------------------------
   /*
     	select @co = min(JBCo) 
    	from inserted i
      	while @co is not null
        	begin
    		select @hqtaxgrp = TaxGroup
    		from bHQCO
    		where HQCo = @co
    
         	select @mth = min(BillMonth) 
   
   
    		from inserted i 
    		where JBCo = @co
         	while @mth is not null
            	begin
              	select @billnum = min(BillNumber) 
    			from inserted i 
    			where JBCo = @co and BillMonth = @mth
               	while @billnum is not null
               		begin
                  	select @procgroup = ProcessGroup, @contract = Contract
                  	from bJBIN 
    				where JBCo = @co and BillMonth = @mth and BillNumber = @billnum
    
                	select @line = min(Line) 
    				from inserted i 
    				where JBCo = @co and BillMonth = @mth and BillNumber = @billnum
                 	while @line is not null
          				begin
                     	select @item = Item, @template = Template, @tempseq = TemplateSeq,
                         	@linekey = LineKey, @linetype = LineType
                       	from inserted i 
    					where JBCo = @co and BillMonth = @mth and BillNumber = @billnum 
    						and Line = @line
     
                      	select @line = min(Line) 
    					from inserted i 
    					where JBCo = @co and BillMonth = @mth and BillNumber = @billnum 
    						and Line > @line
                    	end
         			select @billnum = min(BillNumber) 
    				from inserted i 
    				where JBCo = @co and BillMonth = @mth and BillNumber > @billnum
                  	end
              	select @mth = min(BillMonth) 
    			from inserted i 
    			where JBCo = @co and BillMonth > @mth
              	end
         	select @co = min(JBCo) 
    		from inserted i 
    		where JBCo > @co
         	end
     	end
   */
   --------------------------------  REM'D FOR ISSUE #22126 ----------------------------------------------
    
    /*Issue 13667*/
    If exists(select * from inserted i join bJBCO c on i.JBCo = c.JBCo where c.AuditBills = 'Y')
    BEGIN
    If Update(Item)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIL', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line),i.JBCo, 'C', 'Item', d.Item, i.Item, getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where isnull(d.Item,'') <> isnull(i.Item,'')
    		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End
    
    If Update(Contract)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIL', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line),i.JBCo, 'C', 'Contract', d.Contract, i.Contract, getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where isnull(d.Contract,'') <> isnull(i.Contract,'')
    		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End
    
    If Update(Job)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIL', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line),i.JBCo, 'C', 'Job', d.Job, i.Job, getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where isnull(d.Job,'') <> isnull(i.Job,'')
    		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End
    
    If Update(PhaseGroup)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIL', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line),i.JBCo, 'C', 'PhaseGroup', convert(varchar(3), d.PhaseGroup), convert(varchar(3), i.PhaseGroup), getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where isnull(d.PhaseGroup,0) <> isnull(i.PhaseGroup,0)
    		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End
    
    If Update(Phase)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIL', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line),i.JBCo, 'C', 'Phase', d.Phase, i.Phase, getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where isnull(d.Phase,'') <> isnull(i.Phase,'')
    		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End
    
    If Update(Date)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIL', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line),i.JBCo, 'C', 'Date', convert(varchar(8), d.Date,1), convert(varchar(8), i.Date,1), getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where isnull(d.Date,'') <> isnull(i.Date,'')
    		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End
    
    If Update(Template)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIL', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line),i.JBCo, 'C', 'Template', d.Template, i.Template, getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where isnull(d.Template,'') <> isnull(i.Template,'')
    		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End
    
    If Update(TemplateSeq)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIL', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line),i.JBCo, 'C', 'TemplateSeq', convert(varchar(10), d.TemplateSeq), convert(varchar(10), i.TemplateSeq), getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where isnull(d.TemplateSeq,-2147483648) <> isnull(i.TemplateSeq,-2147483648)
    		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End
    
    If Update(TemplateSortLevel)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIL', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line),i.JBCo, 'C', 'TemplateSortLevel', convert(varchar(3), d.TemplateSortLevel), convert(varchar(3), i.TemplateSortLevel), getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where isnull(d.TemplateSortLevel,0) <> isnull(i.TemplateSortLevel,0)
    		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End
    
    If Update(TemplateSeqSumOpt)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIL', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line),i.JBCo, 'C', 'TemplateSeqSumOpt', convert(varchar(3), d.TemplateSeqSumOpt), convert(varchar(3), i.TemplateSeqSumOpt), getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where isnull(d.TemplateSeqSumOpt,0) <> isnull(i.TemplateSeqSumOpt,0)
    		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End
    
    If Update(TemplateSeqGroup)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIL', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line),i.JBCo, 'C', 'TemplateSeqGroup', convert(varchar(10), d.TemplateSeqGroup), convert(varchar(10), i.TemplateSeqGroup), getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where isnull(d.TemplateSeqGroup,-2147483648) <> isnull(i.TemplateSeqGroup,-2147483648)
    		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End
    
    If Update(LineType)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIL', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line),i.JBCo, 'C', 'LineType', d.LineType, i.LineType, getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where isnull(d.LineType,'') <> isnull(i.LineType,'')
    		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End
    
    If Update(Description)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIL', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line),i.JBCo, 'C', 'Description', d.Description, i.Description, getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where isnull(d.Description,'') <> isnull(i.Description,'')
    		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End
    
    If Update(TaxGroup)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIL', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line),i.JBCo, 'C', 'TaxGroup', convert(varchar(3), d.TaxGroup), convert(varchar(3), i.TaxGroup), getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where isnull(d.TaxGroup,0) <> isnull(i.TaxGroup,0)
    		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End
    
    If Update(TaxCode)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIL', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line),i.JBCo, 'C', 'TaxCode', d.TaxCode, i.TaxCode, getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where isnull(d.TaxCode,'') <> isnull(i.TaxCode,'')
    		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End
    
    If Update(MarkupOpt)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIL', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line),i.JBCo, 'C', 'MarkupOpt', d.MarkupOpt, i.MarkupOpt, getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where isnull(d.MarkupOpt,'') <> isnull(i.MarkupOpt,'')
    		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End
    
    If Update(MarkupRate)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIL', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line),i.JBCo, 'C', 'MarkupRate', convert(varchar(17), d.MarkupRate), convert(varchar(17), i.MarkupRate), getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where d.MarkupRate <> i.MarkupRate
    		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End
    
    If Update(Basis)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIL', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line),i.JBCo, 'C', 'Basis', convert(varchar(13), d.Basis), convert(varchar(13), i.Basis), getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where d.Basis <> i.Basis
    		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End
    
    If Update(MarkupAddl)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIL', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line),i.JBCo, 'C', 'MarkupAddl', convert(varchar(13), d.MarkupAddl), convert(varchar(13), i.MarkupAddl), getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where d.MarkupAddl <> i.MarkupAddl
    		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End
    
    If Update(MarkupTotal)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIL', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line),i.JBCo, 'C', 'MarkupTotal', convert(varchar(13), d.MarkupTotal), convert(varchar(13), i.MarkupTotal), getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where d.MarkupTotal <> i.MarkupTotal
    		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End
    
    If Update(Total)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIL', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line),i.JBCo, 'C', 'Total', convert(varchar(13), d.Total), convert(varchar(13), i.Total), getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where d.Total <> i.Total
    		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End
    
    If Update(Retainage)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIL', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line),i.JBCo, 'C', 'Retainage', convert(varchar(13), d.Retainage), convert(varchar(13), i.Retainage), getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where d.Retainage <> i.Retainage
    		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End
    
    If Update(Discount)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIL', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line),i.JBCo, 'C', 'Discount', convert(varchar(13), d.Discount), convert(varchar(13), i.Discount), getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where d.Discount <> i.Discount
    		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End
    
    If Update(LineKey)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIL', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line),i.JBCo, 'C', 'LineKey', d.LineKey, i.LineKey, getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line
    	Join bJBCO c on c.JBCo = i.JBCo
    	Where isnull(d.LineKey,'') <> isnull(i.LineKey,'')
    		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End
    
    If Update(TemplateGroupNum)
    	Begin
    	Insert bHQMA (TableName, KeyString, Co, RecType, FieldName, OldValue, NewValue, [DateTime], UserName)
    	Select 'bJBIL', 'JBCo: ' + convert(varchar(3),i.JBCo) + 'BillMonth: ' + convert(varchar(8), i.BillMonth,1) + 'BillNumber: ' + convert(varchar(10),i.BillNumber) + 'Line: ' + convert(varchar(10),i.Line),i.JBCo, 'C', 'TemplateGroupNum', convert(varchar(10), d.TemplateGroupNum), convert(varchar(10), i.TemplateGroupNum), getdate(), SUSER_SNAME()
    	From inserted i
    	Join deleted d on d.JBCo = i.JBCo and d.BillMonth = i.BillMonth and d.BillNumber = i.BillNumber and d.Line = i.Line
    		Join bJBCO c on c.JBCo = i.JBCo
    	Where isnull(d.TemplateGroupNum,-2147483648) <> isnull(i.TemplateGroupNum,-2147483648)
    		and c.AuditBills = 'Y' and i.AuditYN = 'Y'
    	End
    END
    
   return
    
   error:
   select @errmsg = @errmsg + ' - cannot update JBIL!'
   
   if @openJBILcursor = 1
   	begin
   	close bJBIL_insert
   	deallocate bJBIL_insert
   	select @openJBILcursor = 0
   	end
   
   RAISERROR(@errmsg, 11, -1);
   rollback transaction
   
   
  
 




GO
ALTER TABLE [dbo].[bJBIL] WITH NOCHECK ADD CONSTRAINT [CK_bJBIL_AuditYN] CHECK (([AuditYN]='Y' OR [AuditYN]='N'))
GO
ALTER TABLE [dbo].[bJBIL] WITH NOCHECK ADD CONSTRAINT [CK_bJBIL_Purge] CHECK (([Purge]='Y' OR [Purge]='N'))
GO
ALTER TABLE [dbo].[bJBIL] WITH NOCHECK ADD CONSTRAINT [CK_bJBIL_ReseqYN] CHECK (([ReseqYN]='Y' OR [ReseqYN]='N'))
GO
CREATE UNIQUE CLUSTERED INDEX [biJBIL] ON [dbo].[bJBIL] ([JBCo], [BillMonth], [BillNumber], [Line]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biJBILLineKey] ON [dbo].[bJBIL] ([JBCo], [LineKey], [TemplateSeq], [Item]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [biJBILTempSeq] ON [dbo].[bJBIL] ([JBCo], [Template], [TemplateSeq], [LineType]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
CREATE UNIQUE NONCLUSTERED INDEX [biKeyID] ON [dbo].[bJBIL] ([KeyID]) WITH (FILLFACTOR=90) ON [PRIMARY]
GO
