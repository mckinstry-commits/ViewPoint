SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.bspJBTandMUpdateSeqAddons    Script Date: 8/28/99 9:32:34 AM ******/
CREATE proc [dbo].[bspJBTandMUpdateSeqAddons]
/***********************************************************
* CREATED BY: kb 6/14/00
* MODIFIED BY: kb 2/7/01 issue #12222
* 		kb 6/4/1 issue #12332
*    	kb 2/7/2 - issue #16110
*     	kb 5/1/2 - issue #17095
*     	bc 5/7/2 - issue #17270
*		TJL 07/01/02 - Issue #17701, Correct Updates to all values, Particularily Multiple DetAddons.
*		TJL 01/27/03 - Issue #20090, Total Addons do not always Update when JBIL line deleted
*		TJL 04/22/03 - Issue #20090, Rejection Fix #1.
*		TJL 08/25/03 - Issue #20471, Combine Total Addon Values for ALL Items under a single Item
*		TJL 09/20/03 - Issue #22126, Performance mods, added noLocks to this procedure
*		TJL 03/31/04 - Issue #24189, Check for invalid Template Seq Item
*		TJL 09/29/04 - Issue #25622, Remove #JBIDTemp table, Run this proc from bspJBTandMInit
*		TJL 09/30/04 - Issue #25612, Add MarkupOpt (H - Rate by Hour) to Detail Addons, Remove psuedos
*		TJL 12/29/04 - Issue #26006, Fix Total Addons against other Total Addons not updating on Manual change
*		TJL 10/13/05 - Issue #29863, Allow Manual Changes to TotalAddons and prevent resetting change when record saved
*		TJL 08/10/06 - Issue #122144, DetailAddons against other DetailAddons calculating incorrectly.
*		TJL 08/07/08 - Issue #128962, JB International Sales Tax
*		TJL 08/20/10 - Issue #140764, TaxRate calculations accurate to only 5 decimal places.  Needs to be 6
*		AMR 06/22/11 - Issue TK-07089, Fixing performance issue with if exists statement.
*
* USED IN:
*	bspJBTandMInit
*	btJBIDu
*	btJBILd
*	btJBILi
*	btJBILu
*
* USAGE:
*
* INPUT PARAMETERS
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs
* RETURN VALUE
*   0         success
*   1         Failure
*
*cycle thru for template seq, add addon then go thru for that addon in
*backwards order and add all it is subject to, maybe do all zeros, then
*go back through and update amts.
*****************************************************/
  
(@co bCompany,  @billmth bMonth, @billnum int, @line int, @oldamt bDollar,
	@newamt bDollar, @template varchar(10), @tempseq int, @linekey varchar(100),
 	@oldunits bUnits, @newunits bUnits, @delitempassedin bContractItem,
 	@msg varchar(255) output)
as

set nocount on

declare @rcode int,	@subtotal bDollar, @markupopt char(1), 
 	@detaddonseq int, @totaddonseq int, @contract bContract, @item bContractItem,
 	@totlinekey varchar(100), @custgroup bGroup, @customer bCustomer, @tempseqitem bContractItem,
 	@jccimarkuprate bRate, @markuprate numeric(17,6), @itemtotal bDollar, @markuptotal bDollar,
 	@taxgroup bGroup, @taxcode bTaxCode, @itemtaxgroup bGroup, @itemtaxcode bTaxCode,
 	@taxrcode int, @taxerrmsg varchar(255), @detaddonseq2 int,
 	--International Sales Tax
	@arco bCompany, @arcoinvoicetaxyn bYN, @arcotaxretgyn bYN, @arcosepretgtaxyn bYN,
	@retgsubtotal bDollar

declare @openitemcursor tinyint, @openaddonseqcursor tinyint, @openaddonseqcursor2 tinyint

select @rcode = 0, @openitemcursor = 0, @openaddonseqcursor = 0,  @openaddonseqcursor2 = 0

select @custgroup = n.CustGroup, @customer = n.Customer, @contract = n.Contract,
	@arco = c.ARCo, @arcoinvoicetaxyn = a.InvoiceTax, @arcotaxretgyn = a.TaxRetg, @arcosepretgtaxyn = a.SeparateRetgTax
from bJBIN n with (nolock)
join bJCCO c with (nolock) on c.JCCo = n.JBCo	
join bARCO a with (nolock) on a.ARCo = c.ARCo
where n.JBCo = @co and n.BillMonth = @billmth and n.BillNumber = @billnum
  
/************************************ DETAIL ADDON ADJUSTMENTS ************************************/

/* This process, called from triggers, is suspended during auto initialization. 'bspJBTandMInit'*/
if exists(select 1 from bJBTA a with (nolock)
 	join bJBTS s with (nolock) on s.JBCo = a.JBCo and s.Template = a.Template and s.Seq = a.AddonSeq
 	join bJBIL l with (nolock) on l.JBCo = a.JBCo and l.Template = a.Template and l.TemplateSeq = a.AddonSeq
 	where a.JBCo = @co and l.BillMonth = @billmth and l.BillNumber = @billnum
		and a.Template = @template and a.Seq = @tempseq
 		and s.Type='D' and l.LineType = 'D'
 		-- removing group by because we are doing an if exists so lets not waste time
 	)
 
 	/* If exists begin Detail addons updates */
 	begin
 	declare bcAddonSeq cursor local fast_forward for
 	select a.AddonSeq
 	from bJBTA a with (nolock)
 	join bJBTS s with (nolock) on s.JBCo = a.JBCo and s.Template = a.Template and s.Seq = a.AddonSeq
 	join bJBIL l with (nolock) on l.JBCo = a.JBCo and l.Template = a.Template and l.TemplateSeq = a.AddonSeq
 	where a.JBCo = @co and l.BillMonth = @billmth and l.BillNumber = @billnum
		and a.Template = @template and a.Seq = @tempseq
 		and s.Type='D' and l.LineType = 'D' 
		and l.LineKey = @linekey
 	group by a.JBCo, a.Template, a.AddonSeq
 
  	open bcAddonSeq
  	select @openaddonseqcursor = 1
 
  	fetch next from bcAddonSeq into @detaddonseq
 
  	while @@fetch_status = 0
      	begin	/* Begin detaddonseq Loop */
  		select @markupopt = MarkupOpt, @item = Item 
  		from JBIL with (nolock)
  		where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
  			and LineKey = @linekey and TemplateSeq = @detaddonseq

  		select @subtotal = 0, @retgsubtotal = 0
  
  		/* Get new @subtotal/Basis for this Detail Addon */
  		if @markupopt = 'U'
          	begin
  			/* Get Source Line Number for this LineKey and Item. */
  			select @line = Line 
  			from JBIL with (nolock)
  			where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
  				and LineKey = @linekey and LineType = 'S' and Item = @item
  			
  			/* Get subtotal/Basis based on Units for this Source Line. */
       		select @subtotal = isnull(sum(d.Units),0)
           	from bJBID d with (nolock)
           	join bJBIL l with (nolock) on l.JBCo = d.JBCo and l.BillMonth = d.BillMonth
              	and l.BillNumber = d.BillNumber and l.Line = d.Line
           	where l.JBCo = @co and l.BillMonth = @billmth and l.BillNumber = @billnum
              	and l.Line = @line
  			end
  
  		if @markupopt = 'H'
  			begin
  			/* Get Source Line Number for this LineKey and Item. */
  			select @line = Line 
  			from JBIL with (nolock)
  			where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
  				and LineKey = @linekey and LineType = 'S' and Item = @item
  			
  			/* Get subtotal/Basis based on Hours for this Source Line. */
       		select @subtotal = isnull(sum(d.Hours),0)
           	from bJBID d with (nolock)
           	join bJBIL l with (nolock) on l.JBCo = d.JBCo and l.BillMonth = d.BillMonth
              	and l.BillNumber = d.BillNumber and l.Line = d.Line
           	where l.JBCo = @co and l.BillMonth = @billmth and l.BillNumber = @billnum
              	and l.Line = @line
  			end
  
		if @markupopt not in ('U', 'H')
  			begin
  			/* Get Totals from those sequence/lines that this addon applies against
  			   and whose sequences are earlier than this addon sequence. */
       		select @subtotal = isnull(sum(l.Total),0), @retgsubtotal = isnull(sum(Retainage),0) 
  			from bJBIL l with (nolock)
  			join bJBTA a with (nolock) on a.JBCo=l.JBCo and a.Template=l.Template and a.Seq=l.TemplateSeq
             	where l.JBCo = @co and l.BillMonth = @billmth and l.BillNumber = @billnum
  				and (l.Item = @item or (l.Item is null and @item is null))
  				and l.LineKey = @linekey and l.TemplateSeq < @detaddonseq 
  				and a.AddonSeq = @detaddonseq and LineType <> 'M'

			/* Begin Tax Basis (@subtotal) calculations */
			if @markupopt = 'T' 
				begin
				if @arcotaxretgyn = 'Y' and @arcosepretgtaxyn = 'N'
					begin
					/* Standard US */
					select @subtotal = @subtotal		
					end
				if @arcotaxretgyn = 'Y' and @arcosepretgtaxyn = 'Y'
					begin
					/* International with RetgTax */
					select @subtotal = @subtotal - @retgsubtotal		
					end
				if @arcotaxretgyn = 'N'
					begin
					/* International no RetgTax */
					select @subtotal = @subtotal - @retgsubtotal
					end			
				end
			if @markupopt = 'X'
				begin
				if @arcotaxretgyn = 'Y' and @arcosepretgtaxyn = 'N'		--This combination not allowed by Template Setup
					begin
					/* Standard US */
					select @subtotal = 0	--Just in Case:  Probably there is no TempSeq using MarkupOpt X-Retainage Tax		
					end
				if @arcotaxretgyn = 'Y' and @arcosepretgtaxyn = 'Y'
					begin
					/* International with RetgTax */
					select @subtotal = @retgsubtotal	
					end
				if @arcotaxretgyn = 'N'									--This combination not allowed by Template Setup
					begin
					/* International no RetgTax */
					select @subtotal = 0	--Just in Case:  Probably there is no TempSeq using MarkupOpt X-Retainage Tax
					end	
				end
  			end

  		/* Update calculations based on new Basis value */
   		update bJBIL 
  		set Basis = @subtotal,
     		MarkupTotal = case when MarkupOpt in ('D','R') then 0 else isnull(MarkupAddl,0) + (@subtotal * isnull(MarkupRate,0)) end,
   			Total = case when MarkupOpt in ('D','R') then 0 else isnull(MarkupAddl,0) + (@subtotal * isnull(MarkupRate,0)) end,
   		 	Retainage = case MarkupOpt when 'R' then @subtotal * isnull(MarkupRate,0) else 0 end,
  	   		Discount = case MarkupOpt when 'D' then @subtotal * isnull(MarkupRate,0) else 0 end,
   			AuditYN = 'N'
   		from bJBIL with (nolock) 
  		where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
  			and (Item = @item or (Item is null and @item is null))
   		  	and LineKey = @linekey and TemplateSeq = @detaddonseq
  	
  		update bJBIL set AuditYN = 'Y'
   		from bJBIL with (nolock)
  		where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
  			and (Item = @item or (Item is null and @item is null))
   			and LineKey = @linekey and TemplateSeq = @detaddonseq
   	
		/********************* DETAIL ADDONS AGAINST OTHER DETAIL ADDONS ADJUSTMENTS ***********************/
		/* As a result of the International Sales Tax issue and the need to calculate Tax on a Retainage amount
		   it became necessary to run this second loop to pick up those remaining Detail Addons applied against other 
		   Detail Addons but NOT also applied against a Source sequence.  Because these remaining Detail Addons are not  
		   also applied against a Source sequence, they get overlooked during the first loop. 
		   ***Note Limitation ***
		   We can have Detail Addons that apply against other Detail Addons but only IF the other Detail Addons 
		   themselves are applied against Source sequences.  In other words I can have a RetgTax Detail Addon that
		   applies against a Retainage Detail addon because the Retainage Detail Addon does apply against Source
		   sequences.  I cannot (ILLEGAL SETUP) apply another Detail Addon against the RetgTax Detail Addon 
		   described above because it applies only against the Retainage Detail Addon and nothing else. */
		if exists(select 1 from bJBTA a with (nolock)
			join bJBTS s with (nolock) on s.JBCo = a.JBCo and s.Template = a.Template and s.Seq = a.AddonSeq
			join bJBIL l with (nolock) on l.JBCo = a.JBCo and l.Template = a.Template and l.TemplateSeq = a.AddonSeq
			where a.JBCo = @co and l.BillMonth = @billmth and l.BillNumber = @billnum
				and a.Template = @template and a.Seq = @detaddonseq
				and s.Type='D' and l.LineType = 'D'
			group by a.JBCo, a.Template, a.AddonSeq)
	 
			/* If exists begin Detail addons on other Detail addons updates */
			begin
			declare bcAddonSeq2 cursor local fast_forward for
			select a.AddonSeq
			from bJBTA a with (nolock)
			join bJBTS s with (nolock) on s.JBCo = a.JBCo and s.Template = a.Template and s.Seq = a.AddonSeq
			join bJBIL l with (nolock) on l.JBCo = a.JBCo and l.Template = a.Template and l.TemplateSeq = a.AddonSeq
			where a.JBCo = @co and l.BillMonth = @billmth and l.BillNumber = @billnum
				and a.Template = @template and a.Seq = @detaddonseq
				and s.Type='D' and l.LineType = 'D' 
				and l.LineKey = @linekey
			group by a.JBCo, a.Template, a.AddonSeq
	 
			open bcAddonSeq2
			select @openaddonseqcursor2 = 1
		 
			fetch next from bcAddonSeq2 into @detaddonseq2
	 
			while @@fetch_status = 0
  				begin	/* Begin detail addons on other detail addons Loop */
				select @markupopt = MarkupOpt, @item = Item 
				from JBIL with (nolock)
				where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
					and LineKey = @linekey and TemplateSeq = @detaddonseq2

				select @subtotal = 0, @retgsubtotal = 0
	  
				/* Get new @subtotal/Basis for this Detail Addon */
				if @markupopt = 'U'
      				begin
					/* Get Source Line Number for this LineKey and Item. */
					select @line = Line 
					from JBIL with (nolock)
					where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
						and LineKey = @linekey and LineType = 'S' and Item = @item
		  			
					/* Get subtotal/Basis based on Units for this Source Line. */
   					select @subtotal = isnull(sum(d.Units),0)
       				from bJBID d with (nolock)
       				join bJBIL l with (nolock) on l.JBCo = d.JBCo and l.BillMonth = d.BillMonth
          				and l.BillNumber = d.BillNumber and l.Line = d.Line
       				where l.JBCo = @co and l.BillMonth = @billmth and l.BillNumber = @billnum
          				and l.Line = @line
					end
	  
				if @markupopt = 'H'
					begin
					/* Get Source Line Number for this LineKey and Item. */
					select @line = Line 
					from JBIL with (nolock)
					where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
						and LineKey = @linekey and LineType = 'S' and Item = @item
		  			
					/* Get subtotal/Basis based on Hours for this Source Line. */
   					select @subtotal = isnull(sum(d.Hours),0)
       				from bJBID d with (nolock)
       				join bJBIL l with (nolock) on l.JBCo = d.JBCo and l.BillMonth = d.BillMonth
          				and l.BillNumber = d.BillNumber and l.Line = d.Line
       				where l.JBCo = @co and l.BillMonth = @billmth and l.BillNumber = @billnum
          				and l.Line = @line
					end
	  
				if @markupopt not in ('U', 'H')
					begin
					/* Get Totals from those sequence/lines that this addon applies against
					   and whose sequences are earlier than this addon sequence. */
   					select @subtotal = isnull(sum(l.Total),0), @retgsubtotal = isnull(sum(Retainage),0) 
					from bJBIL l with (nolock)
					join bJBTA a with (nolock) on a.JBCo=l.JBCo and a.Template=l.Template and a.Seq=l.TemplateSeq
         				where l.JBCo = @co and l.BillMonth = @billmth and l.BillNumber = @billnum
						and (l.Item = @item or (l.Item is null and @item is null))
						and l.LineKey = @linekey and l.TemplateSeq < @detaddonseq2 
						and a.AddonSeq = @detaddonseq2 and LineType <> 'M'

					/* Begin Tax Basis (@subtotal) calculations */
					if @markupopt = 'T' 
						begin
						if @arcotaxretgyn = 'Y' and @arcosepretgtaxyn = 'N'
							begin
							/* Standard US */
							select @subtotal = @subtotal		
							end
						if @arcotaxretgyn = 'Y' and @arcosepretgtaxyn = 'Y'
							begin
							/* International with RetgTax */
							select @subtotal = @subtotal - @retgsubtotal		
							end
						if @arcotaxretgyn = 'N'
							begin
							/* International no RetgTax */
							select @subtotal = @subtotal - @retgsubtotal
							end			
						end
					if @markupopt = 'X'
						begin
						if @arcotaxretgyn = 'Y' and @arcosepretgtaxyn = 'N'		--This combination not allowed by Template Setup
							begin
							/* Standard US */
							select @subtotal = 0	--Just in Case:  Probably there is no TempSeq using MarkupOpt X-Retainage Tax		
							end
						if @arcotaxretgyn = 'Y' and @arcosepretgtaxyn = 'Y'
							begin
							/* International with RetgTax */
							select @subtotal = @retgsubtotal	
							end
						if @arcotaxretgyn = 'N'									--This combination not allowed by Template Setup
							begin
							/* International no RetgTax */
							select @subtotal = 0	--Just in Case:  Probably there is no TempSeq using MarkupOpt X-Retainage Tax
							end	
						end
					end

				/* Update calculations based on new Basis value */
				update bJBIL 
				set Basis = @subtotal,
 					MarkupTotal = case when MarkupOpt in ('D','R') then 0 else isnull(MarkupAddl,0) + (@subtotal * isnull(MarkupRate,0)) end,
					Total = case when MarkupOpt in ('D','R') then 0 else isnull(MarkupAddl,0) + (@subtotal * isnull(MarkupRate,0)) end,
	 				Retainage = case MarkupOpt when 'R' then @subtotal * isnull(MarkupRate,0) else 0 end,
   					Discount = case MarkupOpt when 'D' then @subtotal * isnull(MarkupRate,0) else 0 end,
					AuditYN = 'N'
				from bJBIL with (nolock) 
				where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
					and (Item = @item or (Item is null and @item is null))
	  				and LineKey = @linekey and TemplateSeq = @detaddonseq2
		  	
				update bJBIL set AuditYN = 'Y'
				from bJBIL with (nolock)
				where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
					and (Item = @item or (Item is null and @item is null))
					and LineKey = @linekey and TemplateSeq = @detaddonseq2
		   	
				/* Get next addon for the line's template seq. */
				fetch next from bcAddonSeq2 into @detaddonseq2
				end		/* End detail addons on other detail addons Loop */
	  
			if @openaddonseqcursor2 = 1
				begin
				close bcAddonSeq2
				deallocate bcAddonSeq2
				select @openaddonseqcursor2 = 0
				end
			end		

  		/* Get next addon for the line's template seq. */
  		fetch next from bcAddonSeq into @detaddonseq
  		end		/* End detaddonseq Loop */
  
  	if @openaddonseqcursor = 1
  		begin
  		close bcAddonSeq
  		deallocate bcAddonSeq
  		select @openaddonseqcursor = 0
  		end
 	end		/* End Detail Addon Loop */

/********************************** TOTAL ADDON ADJUSTMENTS *****************************************/

/* This process is suspended in triggers during auto initialization. 'bspJBTandMInit'
   It is no mistake that the Total Addon Update process below differs from what you see above for the
   Detail Addons.  In this process we can update ALL Total Addons without a big performance hit to 
   assure that Total Addons applied against only other Total Addons or only Detail Addons are updated
   correctly. */ 
if exists(select 1 from bJBTA a with (nolock)
 		join bJBTS s with (nolock) on s.JBCo = a.JBCo and s.Template = a.Template and s.Seq = a.AddonSeq
 		join bJBIL l with (nolock) on l.JBCo = a.JBCo and l.Template = a.Template and l.TemplateSeq = a.AddonSeq
  		where a.JBCo = @co and l.BillMonth = @billmth and l.BillNumber = @billnum 
			and a.Template = @template		--and a.Seq = @tempseq		/* Issue#26006: Removed for T-Addons against other T-Addons */
  			and s.Type='T'and l.LineType = 'T'
  		group by a.JBCo, a.Template, a.AddonSeq)
  	/* If exists begin Total addons updates */
  	begin
  	if @contract is not null
  		begin	/* Begin Contract Processing Loop */
  		/*************** First Process Total Addons that will be BROKEN OUT by Item **************/
  		select @item = Item
  		from bJBIL with (nolock)
  		where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
  			and Template = @template and TemplateSeq = @tempseq
  			and LineKey = @linekey
  
  		/* Under most circumstances @item will be obtained above and Total Addons against
  		   a contract bill will be recalculated correctly when a JBIL or JBID line gets
  		   inserted, updated or deleted.  
  		   The Exception:  When a line is deleted AND if no DETAIL ADDONS exists for the line
  		   being deleted ((Detail Addons are not based on retreiving @item directly from
  		   the line actually being deleted and therefore will recalculate and
  		   inturn trigger this procedure and in a sense provide the missing
  		   @item value)), then the above code will fail to return a value for @item and the
  		   result is TOTAL ADDONS do not get updated. 
  		   The Fix:  Pass in 'deleted.Item' from the btJBILd trigger. */
  		select @item = isnull(@item, @delitempassedin)
  
		declare bcAddonSeq cursor local fast_forward for
		select a.AddonSeq
		from bJBTA a with (nolock)
		join bJBTS s with (nolock) on s.JBCo = a.JBCo and s.Template = a.Template and s.Seq = a.AddonSeq
		join bJBIL l with (nolock) on l.JBCo = a.JBCo and l.Template = a.Template and l.TemplateSeq = a.AddonSeq
		where a.JBCo = @co and l.BillMonth = @billmth and l.BillNumber = @billnum 
			and a.Template = @template			-- and a.Seq = @tempseq		/* Issue#26006: Removed for T-Addons against other T-Addons */
			and s.Type='T' and l.LineType = 'T' 
			and l.Item = @item and s.ContractItem is null
		group by a.JBCo, a.Template, a.AddonSeq
  
  		open bcAddonSeq
  		select @openaddonseqcursor = 1
  
  		fetch next from bcAddonSeq into @totaddonseq
  		while @@fetch_status = 0
      		begin	/* Begin Total Addon Loop by Item */
			if isnull(@totaddonseq, -1) <= isnull(@tempseq, -1) goto GetNextTotAddSeq	

  			select @markupopt = MarkupOpt, @totlinekey = LineKey
  			from bJBIL with (nolock)
  			where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
  				and Item = @item and TemplateSeq = @totaddonseq
  
       		select @subtotal = 0, @retgsubtotal = 0	
  	
  			/* Get Totals from those sequence/lines that this addon applies against
  			   and whose sequences are earlier than this addon sequence. */
			select @subtotal = isnull(sum(Total),0), @retgsubtotal = isnull(sum(Retainage),0) 
  			from bJBIL l with (nolock)
  			join bJBTA a with (nolock) on a.JBCo=l.JBCo and a.Template=l.Template and a.Seq=l.TemplateSeq
          	where l.JBCo = @co and l.BillMonth = @billmth and l.BillNumber = @billnum
  				and (l.Item = @item or (l.Item is null and @item is null))
  				and l.TemplateSeq < @totaddonseq 
  				and a.AddonSeq = @totaddonseq and LineType <> 'M'
  
			/* Begin Tax Basis (@subtotal) calculations */
			if @markupopt = 'T' 
				begin
				if @arcotaxretgyn = 'Y' and @arcosepretgtaxyn = 'N'
					begin
					/* Standard US */
					select @subtotal = @subtotal		
					end
				if @arcotaxretgyn = 'Y' and @arcosepretgtaxyn = 'Y'
					begin
					/* International with RetgTax */
					select @subtotal = @subtotal - @retgsubtotal		
					end
				if @arcotaxretgyn = 'N'
					begin
					/* International no RetgTax */
					select @subtotal = @subtotal - @retgsubtotal
					end			
				end
			if @markupopt = 'X'
				begin
				if @arcotaxretgyn = 'Y' and @arcosepretgtaxyn = 'N'		--This combination not allowed by Template Setup
					begin
					/* Standard US */
					select @subtotal = 0	--Just in Case:  Probably there is no TempSeq using MarkupOpt X-Retainage Tax		
					end
				if @arcotaxretgyn = 'Y' and @arcosepretgtaxyn = 'Y'
					begin
					/* International with RetgTax */
					select @subtotal = @retgsubtotal	
					end
				if @arcotaxretgyn = 'N'									--This combination not allowed by Template Setup
					begin
					/* International no RetgTax */
					select @subtotal = 0	--Just in Case:  Probably there is no TempSeq using MarkupOpt X-Retainage Tax
					end	
				end

  			/* Update calculations based on new Basis value */
   			update bJBIL 
  			set Basis = @subtotal,
     			MarkupTotal = case when MarkupOpt in ('D','R') then 0 else isnull(MarkupAddl,0) + (@subtotal * isnull(MarkupRate,0)) end,
   				Total = case when MarkupOpt in ('D','R') then 0 else isnull(MarkupAddl,0) + (@subtotal * isnull(MarkupRate,0)) end,
   		 		Retainage = case MarkupOpt when 'R' then @subtotal * isnull(MarkupRate,0) else 0 end,
  	   			Discount = case MarkupOpt when 'D' then @subtotal * isnull(MarkupRate,0) else 0 end,
   				AuditYN = 'N'
   			from bJBIL with (nolock) 
  			where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
  				and (Item = @item or (Item is null and @item is null))
   		  		and LineKey = @totlinekey and TemplateSeq = @totaddonseq
  
           	update bJBIL 
  			set AuditYN = 'Y' 
  			where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum 
  				and (Item = @item or (Item is null and @item is null))
  				and LineKey = @totlinekey and TemplateSeq = @totaddonseq
  
		GetNextTotAddSeq:
            	/* Get next addon for the line's template seq. */
  			fetch next from bcAddonSeq into @totaddonseq
         	end		/* End Total Addon Loop by Item */
  
  		if @openaddonseqcursor = 1
  			begin
  			close bcAddonSeq
  			deallocate bcAddonSeq
  			select @openaddonseqcursor = 0
  			end

  		/*************** Next Process Total Addons that will be APPLIED TO a specific Item **************/
  		/* At this point, we are about to process those Total Addons (skipped above) that contain
  		   a JBTS.ContractItem.  Depending on the MarkupOpt, certain evaluation and processing
  		   must take place.  General rules are:
  	
  		   A)  S - Rate:  Rate can come from 3 locations
  				1) First, from the Template.  (Applied to All Items equally)
  				2) Second, the item specified may be a FEE Item containing a MarkUpRate
  				   (Applied to All Items equally)
  				3) Third, if #1 and #2 are 0.00, then each item's MarkUpRate is applied to
  				   its own basis, added to the others, and redirected to the specified 
  				   FEE Item.
  	
		   B)  T - Tax:  Rate comes only from the specified Tax Item.  rules are:
				1) Apply this rate only to those items marked with the same TaxCode
				2) Skip those items without a TaxCode value
				3) If any one Contract Item has a TaxCode different from the specifed Tax item's
				   TaxCode, then this process must be aborted and user warned. */

		declare bcAddonSeq cursor local fast_forward for
		select a.AddonSeq
		from bJBTA a with (nolock)
		join bJBTS s with (nolock) on s.JBCo = a.JBCo and s.Template = a.Template and s.Seq = a.AddonSeq
		join bJBIL l with (nolock) on l.JBCo = a.JBCo and l.Template = a.Template and l.TemplateSeq = a.AddonSeq
		where a.JBCo = @co and l.BillMonth = @billmth and l.BillNumber = @billnum  
			and a.Template = @template 			-- and a.Seq = @tempseq		/* Issue#26006: Removed for T-Addons against other T-Addons */
			and s.Type='T'and l.LineType = 'T'  
			and s.ContractItem is not null and l.Item = s.ContractItem
		group by a.JBCo, a.Template, a.AddonSeq
  
  		open bcAddonSeq
  		select @openaddonseqcursor = 1
  
  		fetch next from bcAddonSeq into @totaddonseq
  		while @@fetch_status = 0
      		begin	/* Begin Total Addon Loop, combined item */
			If isnull(@totaddonseq, -1) <= isnull(@tempseq, -1) goto GetNextTotAddSeqSpecificItem

  			select @tempseqitem = ContractItem, @markupopt = MarkupOpt
  	  		from bJBTS with (nolock)
  			where JBCo = @co and Template = @template and Seq = @totaddonseq
  
  			If @markupopt = 'S'
  				begin	/* Begin 'S' option Loop */
  				select @jccimarkuprate = MarkUpRate
  				from bJCCI with (nolock)
  				where JCCo = @co and Contract = @contract and Item = @tempseqitem
  	
  				select @markuprate = case when isnull(@jccimarkuprate,0) <> 0 then
  						case MarkupRate when 0 then @jccimarkuprate else MarkupRate end
  						else MarkupRate end
  		  		from bJBTS with (nolock)
  				where JBCo = @co and Template = @template and Seq = @totaddonseq
  
  				/* Fast Process, when MarkupRate comes from Template or from redirected FEE Item */
  				If isnull(@markuprate,0) <> 0
  					begin	/* Begin Fast Process */
  					select @subtotal = 0
  			
  					/* Get Totals from those sequence/lines that this addon applies against
  					and whose sequences are earlier than this addon sequence. */
  			    	select @subtotal = isnull(sum(Total),0) 
  					from bJBIL l with (nolock)
  					join bJBTA a with (nolock) on a.JBCo=l.JBCo and a.Template=l.Template and a.Seq=l.TemplateSeq
  			  		where l.JBCo = @co and l.BillMonth = @billmth and l.BillNumber = @billnum
  						--and (l.Item = @item or (l.Item is null and @item is null))
  						and l.TemplateSeq < @totaddonseq 
  						and a.AddonSeq = @totaddonseq and l.LineType <> 'M'
  
  					select @totlinekey = LineKey
  					from bJBIL with (nolock)
  					where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
  						and Item = @tempseqitem and TemplateSeq = @totaddonseq
  
  					/* update calculations based on new Basis value */
  		 			update bJBIL 
  					set Basis = @subtotal,
  						MarkupTotal = (isnull(@subtotal,0)*isnull(@markuprate,0) + MarkupAddl),
  		 				Total = (isnull(@subtotal,0)*isnull(@markuprate,0) + MarkupAddl),
  		 		 		Retainage = 0,
  			   			Discount = 0,
  		 				AuditYN = 'N'
  		 			from bJBIL with (nolock)
  					where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
  						and (Item = @tempseqitem or (Item is null and @tempseqitem is null))
  		 		  		and LineKey = @totlinekey and TemplateSeq = @totaddonseq
  		
  		         	update bJBIL 
  					set AuditYN = 'Y' 
  					where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum 
  						and (Item = @tempseqitem or (Item is null and @tempseqitem is null))
  						and LineKey = @totlinekey and TemplateSeq = @totaddonseq
  					end		/* End Fast Process */
  				else
  				/* Slower Process, when MarkupRate comes from each individual Item */
  					begin	/* Begin Slower Process */
  					select @subtotal = 0, @markuptotal = 0
  	
  					declare bcItem cursor local fast_forward for
  					select distinct(Item) 
  					from bJBIL with (nolock) 
  					where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
  	
  					/* Open cursor */
  					open bcItem
  					select @openitemcursor = 1
  	
  					fetch next from bcItem into @item
  					while @@fetch_status = 0
  						begin	/* Begin Item Loop */
						select @itemtotal = 0

  						select @jccimarkuprate = MarkUpRate
  						from bJCCI with (nolock)
  						where JCCo = @co and Contract = @contract and Item = @item
  	
  						/* Get Totals from those sequence/lines that this addon applies against
  						and whose sequences are earlier than this addon sequence. */
  				    	select @itemtotal = isnull(sum(Total),0) 
  						from bJBIL l with (nolock)
  						join bJBTA a with (nolock) on a.JBCo=l.JBCo and a.Template=l.Template and a.Seq=l.TemplateSeq
  				  		where l.JBCo = @co and l.BillMonth = @billmth and l.BillNumber = @billnum
  							and (l.Item = @item or (l.Item is null and @item is null))
  							and l.TemplateSeq < @totaddonseq 
  							and a.AddonSeq = @totaddonseq and l.LineType <> 'M'
  	
  						select @subtotal = @subtotal + @itemtotal		--basis
  						select @markuptotal = @markuptotal + (@itemtotal * isnull(@jccimarkuprate, 0))
  	
  						fetch next from bcItem into @item
  						end		/* End Item Loop */
  	
  					if @openitemcursor = 1
  						begin
  						close bcItem
  						deallocate bcItem
  						select @openitemcursor = 0
  						end
  
  					select @totlinekey = LineKey
  					from bJBIL with (nolock)
  					where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
  						and Item = @tempseqitem and TemplateSeq = @totaddonseq
  
  					/* update calculations based on new Basis value */
  		 			update bJBIL 
  					set MarkupRate =  0/* (@markuptotal/@subtotal */,
  						Basis = @subtotal,
  						MarkupTotal = @markuptotal + MarkupAddl,
  		 				Total = @markuptotal + MarkupAddl,
  		 		 		Retainage = 0,
  			   			Discount = 0,
  		 				AuditYN = 'N'
  		 			from bJBIL with (nolock) 
  					where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
  						and (Item = @tempseqitem or (Item is null and @tempseqitem is null))
  		 		  		and LineKey = @totlinekey and TemplateSeq = @totaddonseq
  		
  		         	update bJBIL 
  					set AuditYN = 'Y' 
  					where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum 
  						and (Item = @tempseqitem or (Item is null and @tempseqitem is null))
  						and LineKey = @totlinekey and TemplateSeq = @totaddonseq
  					end 	/* End Slower Process */
  				end		/* End 'S' option Loop */
  
  			If @markupopt in ('T', 'X')
  				begin	/* Begin 'T' option Loop */
  				select @taxgroup = TaxGroup, @taxcode = TaxCode
  				from bJCCI with (nolock)
  				where JCCo = @co and Contract = @contract and Item = @tempseqitem
  
  				if @taxcode is not null			
  					begin	/* Begin taxcode not null loop */
  					if exists(select top 1 1 from bJCCI with (nolock) where JCCo = @co and Contract = @contract
  							and TaxCode is not null			-- Therefore TaxGroup will not be null here
  							and (TaxGroup <> @taxgroup or TaxCode <> @taxcode))
  						begin
  						/* Cannot Process Items using the designated Item TaxCode rate */
  						select @taxerrmsg = 'TaxGroup or TaxCode on one or more Contract Items for Contract: '
  						select @taxerrmsg = @taxerrmsg + @contract + ' does not match the TaxGroup/TaxCode for item: '
  						select @taxerrmsg = @taxerrmsg + isnull(@tempseqitem,'') + ' and was not processed.'
  						select @taxrcode = 12
  						end
  					else
  						begin	/* Begin Process Tax loop */
  						select @subtotal = 0, @retgsubtotal = 0		--@itemtotal = 0, @markuptotal = 0
  		 
  						select @totlinekey = LineKey
  						from bJBIL with (nolock)
  						where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
  							and Item = @tempseqitem and TemplateSeq = @totaddonseq
  
						select @subtotal = isnull(sum(l.Total),0), @retgsubtotal = isnull(sum(l.Retainage),0)	 
						from bJBIL l with (nolock)
						join bJBTA a with (nolock) on a.JBCo=l.JBCo and a.Template=l.Template and a.Seq=l.TemplateSeq
						join bJCCI i on i.JCCo = l.JBCo and i.Contract = l.Contract and i.Item = l.Item
						where l.JBCo = @co and l.BillMonth = @billmth and l.BillNumber = @billnum
							--and (l.Item = @item or (l.Item is null and @item is null))
							and l.TemplateSeq < @totaddonseq 
							and a.AddonSeq = @totaddonseq and l.LineType <> 'M'
							and i.TaxCode is not null

						/* Begin Tax Basis (@subtotal) calculations */
						if @markupopt = 'T' 
							begin
							if @arcotaxretgyn = 'Y' and @arcosepretgtaxyn = 'N'
								begin
								/* Standard US */
								select @subtotal = @subtotal		
								end
							if @arcotaxretgyn = 'Y' and @arcosepretgtaxyn = 'Y'
								begin
								/* International with RetgTax */
								select @subtotal = @subtotal - @retgsubtotal		
								end
							if @arcotaxretgyn = 'N'
								begin
								/* International no RetgTax */
								select @subtotal = @subtotal - @retgsubtotal
								end			
							end
						if @markupopt = 'X'
							begin
							if @arcotaxretgyn = 'Y' and @arcosepretgtaxyn = 'N'		--This combination not allowed by Template Setup
								begin
								/* Standard US */
								select @subtotal = 0	--Just in Case:  Probably there is no TempSeq using MarkupOpt X-Retainage Tax		
								end
							if @arcotaxretgyn = 'Y' and @arcosepretgtaxyn = 'Y'
								begin
								/* International with RetgTax */
								select @subtotal = @retgsubtotal	
								end
							if @arcotaxretgyn = 'N'									--This combination not allowed by Template Setup
								begin
								/* International no RetgTax */
								select @subtotal = 0	--Just in Case:  Probably there is no TempSeq using MarkupOpt X-Retainage Tax
								end	
							end

  						/* update calculations based on new Basis value */
  			 			update bJBIL 
  						set Basis = @subtotal,
  							MarkupTotal = isnull(MarkupAddl,0) + (@subtotal * isnull(MarkupRate,0)),
  			 				Total = isnull(MarkupAddl,0) + (@subtotal * isnull(MarkupRate,0)),
  			 		 		Retainage = 0,
  				   			Discount = 0,
  			 				AuditYN = 'N'
  			 			from bJBIL with (nolock) 
  						where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
  							and (Item = @tempseqitem or (Item is null and @tempseqitem is null))
  			 		  		and LineKey = @totlinekey and TemplateSeq = @totaddonseq
  			
  			         	update bJBIL 
  						set AuditYN = 'Y' 
  						where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum 
  							and (Item = @tempseqitem or (Item is null and @tempseqitem is null))
  							and LineKey = @totlinekey and TemplateSeq = @totaddonseq
  						end		/* End Process Tax loop */
  					end		/* End taxcode not null loop */			
  				end		/* End 'T' option Loop */
  
		GetNextTotAddSeqSpecificItem:
  			/* Get next Total Addon Seq */
  			fetch next from bcAddonSeq into @totaddonseq
  			end		/* End Total Addon Loop, combined item */
   
  		if @openaddonseqcursor = 1
  			begin
  			close bcAddonSeq
  			deallocate bcAddonSeq
  			select @openaddonseqcursor = 0
  			end
  
  		end		-- End Contract Total Addon Loop
	else
		begin	-- Begin Non-Contract Total Addon Loop
		declare bcAddonSeq cursor local fast_forward for
		select a.AddonSeq
		from bJBTA a with (nolock)
		join bJBTS s with (nolock) on s.JBCo = a.JBCo and s.Template = a.Template and s.Seq = a.AddonSeq
		join bJBIL l with (nolock) on l.JBCo = a.JBCo and l.Template = a.Template and l.TemplateSeq = a.AddonSeq
		where a.JBCo = @co and l.BillMonth = @billmth and l.BillNumber = @billnum 
			and a.Template = @template 			-- and a.Seq = @tempseq		/* Issue#26006: Removed for T-Addons against other T-Addons */
			and s.Type='T'and l.LineType = 'T' 
		group by a.JBCo, a.Template, a.AddonSeq
  
  		open bcAddonSeq
  		select @openaddonseqcursor = 1
  
  		fetch next from bcAddonSeq into @totaddonseq
  		while @@fetch_status = 0
      		begin	-- Begin Total Addon Loop
			If isnull(@totaddonseq, -1) <= isnull(@tempseq, -1) goto GetNextTotAddSeqNonCont

  			select @markupopt = MarkupOpt, @totlinekey = LineKey
  			from bJBIL with (nolock)
  			where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
  				and TemplateSeq = @totaddonseq
  
        	select @subtotal = 0, @retgsubtotal = 0
  	
  			/* Get Totals from those sequence/lines that this addon applies against
  			   and whose sequences are earlier than this addon sequence. */
        	select @subtotal = isnull(sum(Total),0), @retgsubtotal = isnull(sum(l.Retainage),0)  
  			from bJBIL l with (nolock)
  			join bJBTA a with (nolock) on a.JBCo=l.JBCo and a.Template=l.Template and a.Seq=l.TemplateSeq
          	where l.JBCo = @co and l.BillMonth = @billmth and l.BillNumber = @billnum
  				and l.Item is null
  				and l.TemplateSeq < @totaddonseq 
  				and a.AddonSeq = @totaddonseq and LineType <> 'M'
  
			/* Begin Tax Basis (@subtotal) calculations */
			if @markupopt = 'T' 
				begin
				if @arcotaxretgyn = 'Y' and @arcosepretgtaxyn = 'N'
					begin
					/* Standard US */
					select @subtotal = @subtotal		
					end
				if @arcotaxretgyn = 'Y' and @arcosepretgtaxyn = 'Y'
					begin
					/* International with RetgTax */
					select @subtotal = @subtotal - @retgsubtotal		
					end
				if @arcotaxretgyn = 'N'
					begin
					/* International no RetgTax */
					select @subtotal = @subtotal - @retgsubtotal
					end			
				end
			if @markupopt = 'X'
				begin
				if @arcotaxretgyn = 'Y' and @arcosepretgtaxyn = 'N'		--This combination not allowed by Template Setup
					begin
					/* Standard US */
					select @subtotal = 0	--Just in Case:  Probably there is no TempSeq using MarkupOpt X-Retainage Tax		
					end
				if @arcotaxretgyn = 'Y' and @arcosepretgtaxyn = 'Y'
					begin
					/* International with RetgTax */
					select @subtotal = @retgsubtotal	
					end
				if @arcotaxretgyn = 'N'									--This combination not allowed by Template Setup
					begin
					/* International no RetgTax */
					select @subtotal = 0	--Just in Case:  Probably there is no TempSeq using MarkupOpt X-Retainage Tax
					end	
				end

  			/* Update calculations based on new Basis value */
   			update bJBIL 
  			set Basis = @subtotal,
     			MarkupTotal = case when MarkupOpt in ('D','R') then 0 else isnull(MarkupAddl,0) + (@subtotal * isnull(MarkupRate,0)) end,
   				Total = case when MarkupOpt in ('D','R') then 0 else isnull(MarkupAddl,0) + (@subtotal * isnull(MarkupRate,0)) end,
   		 		Retainage = case MarkupOpt when 'R' then @subtotal * isnull(MarkupRate,0) else 0 end,
  	   			Discount = case MarkupOpt when 'D' then @subtotal * isnull(MarkupRate,0) else 0 end,
   				AuditYN = 'N'
   			from bJBIL with (nolock) 
  			where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
  				and Item is null
   		  		and LineKey = @totlinekey and TemplateSeq = @totaddonseq
  			if @@rowcount = 0
  				begin
  				select @msg = 'Total Addons have failed to update! Manual Adjustments required.', @rcode = 1
  				goto bspexit
  				end
  
           	update bJBIL 
  			set AuditYN = 'Y' 
  			where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum 
  				and Item is null 
  				and LineKey = @totlinekey and TemplateSeq = @totaddonseq
  
		GetNextTotAddSeqNonCont:
            	/* Get next addon for the line's template seq. */
  			fetch next from bcAddonSeq into @totaddonseq
          	end		-- End Total Addon Loop
  
  		if @openaddonseqcursor = 1
  			begin
  			close bcAddonSeq
  			deallocate bcAddonSeq
  			select @openaddonseqcursor = 0
  			end
  		end		-- End Non-Contract Total Addon Loop
  	end
  
bspexit:
  
if @openitemcursor = 1
  	begin
  	close bcItem
  	deallocate bcItem
  	select @openitemcursor = 0
  	end
if @openaddonseqcursor = 1
  	begin
  	close bcAddonSeq
  	deallocate bcAddonSeq
  	select @openaddonseqcursor = 0
  	end			
if @openaddonseqcursor2 = 1
	begin
	close bcAddonSeq2
	deallocate bcAddonSeq2
	select @openaddonseqcursor2 = 0
	end
  
/* Modify errmsg text returned to calling procedure. A bJBIL Update error will take
precedence and exits immediately where as a TaxCode Total Addon error continues
the process and only skips the Tax Total Addon. Both will display to user. */
if @rcode = 0 and @taxrcode is not null 
 	begin
  	select @rcode = 1, @msg = isnull(@taxerrmsg, 'Error text missing.')
  	end
  
/* The returned @rcode may be 0 - Success, 
1 - bJBIL Update Failure or Tax Total Addon Failure */
return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspJBTandMUpdateSeqAddons] TO [public]
GO
