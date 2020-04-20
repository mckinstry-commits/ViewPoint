SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspJBTandMProcessTotAddons]
/***********************************************************
* CREATED BY	: TJL 06/21/02 
* MODIFIED BY	: TJL 07/16/02 - Issue #17144, Discount MarkupRate mod
*		TJL 07/31/03 - Issue #21714, Use Markup rate from JCCI if available else use Template markup.
*		TJL 08/25/03 - Issue #20471, Combine Total Addon Values for ALL Items under a single Item
*		TJL 09/20/03 - Issue #22126, Performance mods, added noLocks to this procedure
*		TJL 03/31/04 - Issue #24189, Check for invalid Template Seq Item
*		TJL 09/28/04 - Issue #25622, Remove #JBIDTemp, also remove remaining Psuedo Cursors
*		TJL 05/10/06 - Issue #28227, 6x Rewrite.  Return NULL output in bspJBTandMAddLineTwo call
*		TJL 08/13/07 - Issue #125474, Other Total Addons not calculating against Combined Item Addon (Issue #20471 related)
*		TJL 07/29/08 - Issue #128962, JB International Sales Tax
*		TJL 08/20/10 - Issue #140764, TaxRate calculations accurate to only 5 decimal places.  Needs to be 6
*       KK  09/30/11 - TK-08355 #142979, Pass in itembillgroup to Restrict by Bill Group when initializing. 
*
*
* USED IN:
*	bspJBTandMInit
*
* USAGE:
*
* INPUT PARAMETERS
*	@co, @template, @billnum, @billmth, @contract, @billgroup
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs
*
* RETURN VALUE
*   0		Success
*   1		Not Valid at this time
*	10		bJBCE logged LineKey/Line Number Failure
*	11		bJBCE logged Invalid Template Seq Item Failure
*	12		bJBCE logged TaxCode Failure
*	99		bJBCE logged 10, 11, 12 Undetermined Failure
*
*****************************************************/
   
(@co bCompany,  @template varchar(10), @billnum int, @billmth bMonth,
	@contract bContract, @itembillgroup bBillingGroup, @msg varchar(255) output)
as

set nocount on
   
declare @rcode int, @addontype char(1), @seqdesc varchar(128), @totaddonseq int,
	@tempseqgroup int, @subtotal bDollar, @tempseq int, @markupopt char(1),
	@item bContractItem, @markuprate numeric(17,6), @addlmarkup bDollar,
	@line int, @taxgroup bGroup, @taxcode bTaxCode, @invdate bDate, @taxrate bRate,
	@totlinekey varchar(100), @groupnum int, @retgpct bPct,
	@newline int, @retpct bPct, @custgroup bGroup,
	@customer bCustomer, @payterms bPayTerms, @discrate bPct,
	@jccimarkuprate bRate, @tempseqitem bContractItem, 
	@itemtotal bDollar, @markuptotal bDollar, @itemtaxgroup bGroup, @itemtaxcode bTaxCode,
	@taxrcode int, @linercode int, @seqitemrcode int, @taxerrmsg varchar(255), 
	@lineerrmsg varchar(255), @seqitemerrmsg varchar(255),
	--International Sales Tax
	@arco bCompany, @arcoinvoicetaxyn bYN, @arcotaxretgyn bYN, @arcosepretgtaxyn bYN,
	@retgsubtotal bDollar
   
  
declare @openitemcursor tinyint, @openaddoncursor tinyint
   
select @rcode = 0, @openitemcursor = 0, @openaddoncursor = 0
   
/* Get some other values - Only needs to be done once. */
select @invdate = n.InvDate, @custgroup = n.CustGroup, @customer = n.Customer, @payterms = n.PayTerms,
	@arco = c.ARCo, @arcoinvoicetaxyn = a.InvoiceTax, @arcotaxretgyn = a.TaxRetg, @arcosepretgtaxyn = a.SeparateRetgTax
from bJBIN n with (nolock)
join bJCCO c with (nolock) on c.JCCo = n.JBCo
join bARCO a with (nolock) on a.ARCo = c.ARCo
where n.JBCo = @co and n.BillMonth = @billmth and n.BillNumber = @billnum

select @discrate = DiscRate from bHQPT with (nolock) where PayTerms = @payterms
   
if @contract is not null
/* Begin Contract Total Addon Processing */
begin	/* Begin Contract Processing Loop */
	
	/* This cursor will contain a list of ALL Total Addons seq#'s */
	declare bcTotAddon cursor local fast_forward for
	select a.AddonSeq 
	from dbo.bJBTA a with (nolock)
	join dbo.bJBTS s with (nolock) on s.JBCo = a.JBCo 
								  and s.Template = a.Template 
								  and s.Seq = a.AddonSeq 
	where a.JBCo = @co 
	  and a.Template = @template 
	  and s.Type = 'T' 
	group by a.AddonSeq

	open bcTotAddon
	select @openaddoncursor = 1

	fetch next from bcTotAddon into @totaddonseq
	while @@fetch_status = 0
	begin	/* Begin Total Addon Loop */
		select @markupopt = MarkupOpt, @tempseqgroup = GroupNum, 
			   @addlmarkup = AddonAmt, @addontype = Type, 
			   @seqdesc = Description, @tempseqitem = ContractItem
		from bJBTS with (nolock)
		where JBCo = @co and Template = @template and Seq = @totaddonseq
   
		if @tempseqitem is null 
		begin	/* Begin TempSeq without ContractItem loop */
			/* There is no ContractItem value on this Total Addon Template sequence.
			   This is a standard/common setup and these addons will get processed in a 
			   normal manner, one item at a time. */
			declare bcItem cursor local fast_forward for
			select distinct(Item) 
			from bJBIL with (nolock) 
			where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
				   
			/* Open cursor */
			open bcItem
			select @openitemcursor = 1
		   
			fetch next from bcItem into @item
			while @@fetch_status = 0
			begin	/* Begin Item Loop #1 */
				select @subtotal = 0, @retgsubtotal = 0

				/* LineKey will determine the position of the record as it appears in the 
				   T&M Bill Lines grid.  (Position is not determined by the order of item processing. */
				exec @rcode = bspJBTandMGetLineKey @co, null, null,
   					null, @item, @template, @totaddonseq, null, null,
  					@groupnum, 'Y', @totlinekey output, @msg output
				if @rcode <> 0
				begin
					/* Log and error in bJBCE, skip this Total Addon but keep going to next. */
					select @lineerrmsg = 'Failed to retrieve LineKey value and Total Addon '
					select @lineerrmsg = @lineerrmsg + 'for seq#: ' + convert(varchar(10), @totaddonseq)
					select @lineerrmsg = @lineerrmsg + ', was skipped for Contract: ' + @contract
					select @linercode = 10
				end

				/* Get Next Line number before insert.  (Again determined by LineKey value) */
				exec @rcode = bspJBTandMAddLineTwo @co, @billmth, @billnum, @totlinekey, @template, 
					@totaddonseq, @item, @newline output, null, @msg output
 				if @rcode <> 0
				begin
					/* Log and error in bJBCE, skip this Total Addon but keep going to next. */
					select @lineerrmsg = 'Failed to retrieve LineNumber value and Total Addon '
					select @lineerrmsg = @lineerrmsg + 'for seq#: ' + convert(varchar(10), @totaddonseq)
					select @lineerrmsg = @lineerrmsg + ', was skipped for Contract: ' + @contract
					select @linercode = 10
				end

				select @taxgroup = TaxGroup, @taxcode = TaxCode, 
					   @retpct = RetainPCT, @jccimarkuprate = MarkUpRate
				from bJCCI with (nolock)
				where JCCo = @co and Contract = @contract and Item = @item
				   
				if @taxcode is not null
				begin
					exec bspHQTaxRateGet @taxgroup, @taxcode, @invdate,	@taxrate output, @msg = @msg output
				end

				/* Determine MarkupRate to be applied against a single Items subtotals in JBIL. */
				select @markuprate = case @markupopt
					when 'R' then case when @contract is null then MarkupRate
						else case MarkupRate when 0 then isnull(@retpct,MarkupRate)
							else MarkupRate end end 
					when 'T' then case when @taxcode is not null then @taxrate 
						else MarkupRate end
					when 'X' then case when @taxcode is not null then @taxrate 
						else MarkupRate end
					when 'D' then case when isnull(@discrate,0) <> 0 then
						case MarkupRate when 0 then @discrate else MarkupRate end
						else MarkupRate end
					when 'S' then case when isnull(@jccimarkuprate,0) <> 0 then
						case MarkupRate when 0 then @jccimarkuprate else MarkupRate end
						else MarkupRate end
						else MarkupRate end
				from bJBTS with (nolock)
				where JBCo = @co and Template = @template and Seq = @totaddonseq

				/* Get Totals from those sequence/JBIL Lines that this addon applies against
				and whose sequences are earlier than this addon sequence. */
				select @subtotal = isnull(sum(Total),0), @retgsubtotal = isnull(sum(Retainage),0)
				from bJBIL l with (nolock)
				join bJBTA a with (nolock) on a.JBCo=l.JBCo and a.Template=l.Template and a.Seq=l.TemplateSeq
				where l.JBCo = @co and l.BillMonth = @billmth and l.BillNumber = @billnum
					and (l.Item = @item or (l.Item is null and @item is null))
					and l.TemplateSeq < @totaddonseq 
					and a.AddonSeq = @totaddonseq and l.LineType <> 'M'
   
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

				insert bJBIL (JBCo,BillMonth,BillNumber,Line,Item,Contract,
    				Job,PhaseGroup,Phase,Date,Template,TemplateSeq,
    				TemplateSeqGroup,LineType,Description,TaxGroup,
    				TaxCode,MarkupOpt,MarkupRate,Basis,MarkupAddl,MarkupTotal,Total,
    				Retainage,Discount,NewLine,ReseqYN,LineKey,TemplateGroupNum,
    				LineForAddon,AuditYN)
 				select @co, @billmth,@billnum,@newline,@item,@contract,
    				null,null,null,null,@template,@totaddonseq,
    				@tempseqgroup,@addontype,@seqdesc,
					case when @markupopt in ('T','X') then @taxgroup else null end,
					case when @markupopt in ('T','X') then @taxcode else null end,
        			@markupopt, @markuprate,
					--basis
					@subtotal,
					--addlmarkkup
					@addlmarkup,
     				--markuptotal
     				case when @markupopt in ('D','R')
        				then 0 else @addlmarkup + (@subtotal * @markuprate) end,
    				--total
       				case when @markupopt in ('D','R') 
						then 0 else @addlmarkup	+ (@subtotal * @markuprate) end,
     				--retainage
					case @markupopt when 'R' then (@subtotal * isnull(@markuprate,0))
        				else 0 end,
      				--discount
      				case @markupopt when 'D' then (@subtotal * isnull(@markuprate,0))
        				else 0 end,
  					null,'N',@totlinekey ,@tempseqgroup, null,'N'
	   	
    			update bJBIL 
				set AuditYN = 'Y' 
				where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum 
					  and LineKey = @totlinekey and TemplateSeq = @totaddonseq

   			/* Get next Item */
			nextitem:
			fetch next from bcItem into @item
			end		/* End Item Loop #1 */

			if @openitemcursor = 1
			begin
				close bcItem
				deallocate bcItem
				select @openitemcursor = 0
			end
		end		/* End TempSeq without ContractItem loop */
		else
			begin	/* Begin TempSeq ContractItem exists loop */
			/*************** Process Total Addons that will be APPLIED TO a specific Item **************/
			/* At this point, we are about to process those Total Addon sequences that contain
			   a JBTS.ContractItem value.  Depending on the MarkupOpt, certain evaluation and processing
			   must take place.  General rules are:
		   
			   A)  S - Rate:  Rate can come from 3 locations
					1) First, use MarkkupRate from the Template.  (Applied to All Items equally)
					2) Second, Use the JCCI.MarkupRate from the ContractItem specified on the Template Sequence.
					   (Applied to All Items equally)
					3) Third, if #1 and #2 are 0.00, then each item's MarkUpRate is applied to
					   its own basis, is then added to the others, and redirected to the specified 
					   Template Sequence Item.
		   
			   B)  T - Tax:  Rate comes only from the specified Tax Item.  rules are:
					1) Apply this rate only to those items marked with the same TaxCode.
					2) Skip those items without a TaxCode value.
					3) If any one Contract Item has a TaxCode different from the TemplateSeq Tax item's
					   TaxCode, then this process must be aborted and user warned.
			*/
			
			--TK-08355 (KK)
			if @itembillgroup is not null 
			begin
				if not exists(select 1 
							  from dbo.bJCCI i
							  where i.JCCo = @co 
							    and i.Contract = @contract 
							    and i.BillGroup = @itembillgroup
							    and i.Item = @tempseqitem)
				begin
					goto fetchnext
				end
				
			end
			
			exec @rcode = bspJBTandMGetLineKey @co, null, null,	null, @tempseqitem, @template, 
					@totaddonseq, null, null, @groupnum, 'Y', @totlinekey output, @msg output
    		if @rcode <> 0
			begin
				/* Log and error in bJBCE, skip this Total Addon but keep going to next. */
				select @lineerrmsg = 'Failed to retrieve LineKey value and Total Addon '
				select @lineerrmsg = @lineerrmsg + 'for seq#: ' + convert(varchar(10), @totaddonseq)
				select @lineerrmsg = @lineerrmsg + ', was skipped for Contract: ' + @contract
				select @linercode = 10
			end

			/* Get Next Line number before insert.  (Again determined by LineKey value) */
			exec @rcode = bspJBTandMAddLineTwo @co, @billmth, @billnum, @totlinekey, @template, 
				@totaddonseq, @tempseqitem, @newline output, null, @msg output
			if @rcode <> 0
			begin
				/* Log and error in bJBCE, skip this Total Addon but keep going to next. */
				select @lineerrmsg = 'Failed to retrieve LineNumber value and Total Addon '
				select @lineerrmsg = @lineerrmsg + 'for seq#: ' + convert(varchar(10), @totaddonseq)
				select @lineerrmsg = @lineerrmsg + ', was skipped for Contract: ' + @contract
				select @linercode = 10
			end

			select @jccimarkuprate = MarkUpRate, @taxgroup = TaxGroup, @taxcode = TaxCode
			from bJCCI with (nolock)
			where JCCo = @co and Contract = @contract and Item = @tempseqitem

			If @markupopt = 'S'
			begin	/* Begin 'S' option Loop */
				select @markuprate = case when isnull(@jccimarkuprate,0) <> 0 then
						case MarkupRate when 0 then @jccimarkuprate else MarkupRate end
	      				else MarkupRate end
				from bJBTS with (nolock)
				where JBCo = @co and Template = @template and Seq = @totaddonseq
	   
				/* Fast Process, when MarkupRate comes from Template or from redirected TempSeq ContractItem */
				If isnull(@markuprate,0) <> 0
				begin	/* Begin Fast Process */
					select @subtotal = 0
		   		
					/* Get Totals from ALL those sequence/JBIL Lines that this addon applies against
					and whose sequences are earlier than this addon sequence. */
    				select @subtotal = isnull(sum(Total),0) 
					from bJBIL l with (nolock)
					join bJBTA a with (nolock) on a.JBCo=l.JBCo and a.Template=l.Template and a.Seq=l.TemplateSeq
  					where l.JBCo = @co and l.BillMonth = @billmth and l.BillNumber = @billnum
						--and (l.Item = @item or (l.Item is null and @item is null))
						and l.TemplateSeq < @totaddonseq 
						and a.AddonSeq = @totaddonseq and l.LineType <> 'M'

					insert bJBIL (JBCo,BillMonth,BillNumber,Line,Item,Contract,
    					Job,PhaseGroup,Phase,Date,Template,TemplateSeq,
    					TemplateSeqGroup,LineType,Description,TaxGroup,
    					TaxCode,MarkupOpt,MarkupRate,Basis,MarkupAddl,MarkupTotal,Total,
    					Retainage,Discount,NewLine,ReseqYN,LineKey,TemplateGroupNum,
    					LineForAddon,AuditYN)
 					select @co, @billmth,@billnum,@newline,@tempseqitem,@contract,
    					null,null,null,null,@template,@totaddonseq,
			    		@tempseqgroup,@addontype,@seqdesc,
      					case @markupopt when 'T' then @taxgroup else null end,
      					case @markupopt when 'T' then @taxcode else null end,
        				@markupopt, @markuprate,
						@subtotal,
						--case when @markupopt = 'T' then
        				--	case when @taxcode is null then 0 else @subtotal end 
						--	else @subtotal end,
						@addlmarkup,
     					--markuptotal
     					@addlmarkup + (@subtotal * @markuprate),
    					--total
       					@addlmarkup + (@subtotal*@markuprate),
     					--retainage
						0,
      					--discount
      					0,
  						null,'N',@totlinekey ,@tempseqgroup, null,'N'

    				update bJBIL 
					set AuditYN = 'Y' 
					where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum 
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
				begin	/* Begin Item Loop #2 */
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
				end		/* End Item Loop #2 */
		   
				if @openitemcursor = 1
				begin
					close bcItem
					deallocate bcItem
					select @openitemcursor = 0
					end
	   
					insert bJBIL (JBCo,BillMonth,BillNumber,Line,Item,Contract,
    					Job,PhaseGroup,Phase,Date,Template,TemplateSeq,
    					TemplateSeqGroup,LineType,Description,TaxGroup,
    					TaxCode,MarkupOpt,MarkupRate,Basis,MarkupAddl,MarkupTotal,Total,
    					Retainage,Discount,NewLine,ReseqYN,LineKey,TemplateGroupNum,
    					LineForAddon,AuditYN)
 					select @co, @billmth,@billnum,@newline,@tempseqitem,@contract,
    					null,null,null,null,@template,@totaddonseq,
    					@tempseqgroup,@addontype,@seqdesc,
      					case @markupopt when 'T' then @taxgroup else null end,
      					case @markupopt when 'T' then @taxcode else null end,
        				@markupopt, 0/* (@markuptotal/@subtotal */,
						@subtotal,
						@addlmarkup,
     					--markuptotal
     					@addlmarkup + @markuptotal,
    					--total
       					@addlmarkup + @markuptotal,
     					--retainage
						0,
      					--discount
      					0,
  						null,'N',@totlinekey ,@tempseqgroup, null,'N'
	
	    				update bJBIL 
						set AuditYN = 'Y' 
						where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum 
							and LineKey = @totlinekey and TemplateSeq = @totaddonseq		
				end 	/* End Slower Process */
			end		/* End 'S' option Loop */

			if @markupopt in ('T','X')
			begin	/* Begin 'T' option Loop */
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
						select @subtotal = 0, @retgsubtotal = 0

						exec bspHQTaxRateGet @taxgroup, @taxcode, @invdate,	@taxrate output, @msg = @msg output

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

						insert bJBIL (JBCo,BillMonth,BillNumber,Line,Item,Contract,
		    				Job,PhaseGroup,Phase,Date,Template,TemplateSeq,
		    				TemplateSeqGroup,LineType,Description,TaxGroup,
		    				TaxCode,MarkupOpt,MarkupRate,Basis,MarkupAddl,MarkupTotal,Total,
		    				Retainage,Discount,NewLine,ReseqYN,LineKey,TemplateGroupNum,
		    				LineForAddon,AuditYN)
		 				select @co, @billmth,@billnum,@newline,@tempseqitem,@contract,
		    				null,null,null,null,@template,@totaddonseq,
		    				@tempseqgroup,@addontype,@seqdesc,
		      				case @markupopt when 'T' then @taxgroup else null end,
		      				case @markupopt when 'T' then @taxcode else null end,
		        			@markupopt, @taxrate,
							--basis
							@subtotal,
							--addlmarkup
							@addlmarkup,
		     				--markuptotal
		     				@addlmarkup + (@subtotal * @taxrate),
		    				--total
		       				@addlmarkup + (@subtotal * @taxrate),
		     				--retainage
							0,
		      				--discount
		      				0,
		  					null,'N',@totlinekey ,@tempseqgroup, null,'N'
		
			    			update bJBIL 
							set AuditYN = 'Y' 
							where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum 
								and LineKey = @totlinekey and TemplateSeq = @totaddonseq		
					end		/* End Process Tax loop */
				end		/* End taxcode not null loop */
			end		/* End 'T' option Loop */	
		end		/* End TempSeq ContractItem exists loop */
   				/* Get next Item */
	/* get next addon for the line's template seq */
	fetchnext: --called to initialize only by a select billgroup
	fetch next from bcTotAddon into @totaddonseq
	end		/* End Total Addon Loop */
   
	if @openaddoncursor = 1
	begin
		close bcTotAddon
		deallocate bcTotAddon
		select @openaddoncursor = 0
	end
end		/* End Contract Processing Loop */
else
	/* Begin Non-Contract Total Addon Processing */
	begin	/* Begin Non-Contract Processing Loop */
   	select @taxgroup = TaxGroup, @taxcode = TaxCode 
   	from bARCM with (nolock)
   	where CustGroup = @custgroup and Customer = @customer
   	if @taxcode is not null
   		begin
   		exec bspHQTaxRateGet @taxgroup, @taxcode, @invdate,	@taxrate output, @msg = @msg output
   		end
   
   	declare bcTotAddon cursor local fast_forward for
   	select a.AddonSeq 
   	from bJBTA a with (nolock)
   	join bJBTS s with (nolock) on s.JBCo = a.JBCo and s.Template = a.Template 
   		and s.Seq = a.AddonSeq 
   	where a.JBCo = @co and a.Template = @template and s.Type = 'T' --and a.Seq = @tempseq 
   	group by a.AddonSeq
   
   	open bcTotAddon
   	select @openaddoncursor = 1
   
   	fetch next from bcTotAddon into @totaddonseq
   	while @@fetch_status = 0
       	begin	/* Begin Total Addon Loop */
		select @subtotal = 0, @retgsubtotal = 0

    	exec @rcode = bspJBTandMGetLineKey @co, null, null,
       		null, null, @template, @totaddonseq, null, null,
      		@groupnum, 'Y', @totlinekey output, @msg output
		if @rcode <> 0
   			begin
   			/* Don't Log an error in bJBCE, skip this Total Addon but keep going to next. */
   			select @lineerrmsg = 'Failed to retrieve LineKey value and Total Addon '
   			select @lineerrmsg = @lineerrmsg + 'for seq#: ' + convert(varchar(10), @totaddonseq)
   			select @lineerrmsg = @lineerrmsg + ', was skipped for this Non-Contract BillNumber: .'
   			select @lineerrmsg = @lineerrmsg + convert(varchar(10), @billnum) + ', BillMonth: ' 
   			select @lineerrmsg = @lineerrmsg + convert(varchar(8), @billmth, 1)
   			select @linercode = 1
   			end

		/* Get Next Line number before insert. */
		exec @rcode = bspJBTandMAddLineTwo @co, @billmth, @billnum, @totlinekey, @template, 
			@totaddonseq, null, @newline output, null, @msg output
		if @rcode <> 0
			begin
			/* Log and error in bJBCE, skip this Total Addon but keep going to next. */
			select @lineerrmsg = 'Failed to retrieve  LineNumber value and Total Addon '
			select @lineerrmsg = @lineerrmsg + 'for seq#: ' + convert(varchar(10), @totaddonseq)
			select @lineerrmsg = @lineerrmsg + ', has been skipped.'
			select @linercode = 10
			end

		select @markupopt = MarkupOpt, 
			@markuprate = case MarkupOpt
               	when 'R' then case when @contract is null then MarkupRate
                		else case MarkupRate when 0 then isnull(@retpct,MarkupRate)
               		else MarkupRate end end 
				when 'T' then case when @taxcode is not null then @taxrate 
					else MarkupRate end 
				when 'X' then case when @taxcode is not null then @taxrate 
					else MarkupRate end 
				when 'D' then case when isnull(@discrate,0)<>0 then
					case MarkupRate when 0 then @discrate else MarkupRate end
					else MarkupRate end
                 	else MarkupRate end,
         		@tempseqgroup = GroupNum, @addlmarkup = AddonAmt,
  				@addontype = Type, @seqdesc = Description
       	from bJBTS with (nolock)
		where JBCo = @co and Template = @template and Seq = @totaddonseq

		/* Get Totals from those sequence/lines that this addon applies against
		   and whose sequences are earlier than this addon sequence. */
		select @subtotal = isnull(sum(Total),0), @retgsubtotal = isnull(sum(l.Retainage),0) 
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

   		insert bJBIL (JBCo,BillMonth,BillNumber,Line,Item,Contract,
        	Job,PhaseGroup,Phase,Date,Template,TemplateSeq,
        	TemplateSeqGroup,LineType,Description,TaxGroup,
        	TaxCode,MarkupOpt,MarkupRate,Basis,MarkupAddl,MarkupTotal,Total,
        	Retainage,Discount,NewLine,ReseqYN,LineKey,TemplateGroupNum,
       		LineForAddon,AuditYN)
     	select @co, @billmth,@billnum,@newline,null,null,
        	null,null,null,null,@template,@totaddonseq,
        	@tempseqgroup,@addontype,@seqdesc,
        	case @markupopt when 'T' then @taxgroup else null end,
         	case @markupopt when 'T' then @taxcode else null end
          	,@markupopt, @markuprate,
			--basis
			@subtotal,
			--addlmarkup
			@addlmarkup,
         	--markuptotal
         	case when @markupopt in ('D','R') then 0 else @addlmarkup
            	+ (@subtotal * @markuprate) end,
        	--total
         	case when @markupopt in ('D','R') then 0 else @addlmarkup
            	+ (@subtotal * @markuprate) end,
        	--retainage
			case @markupopt when 'R' then (@subtotal*isnull(@markuprate,0))
           		else 0 end,
         	--discount
         	case @markupopt when 'D' then (@subtotal*isnull(@markuprate,0))
          	else 0 end,
      		null,'N',@totlinekey ,@tempseqgroup, null,'N'

      	update bJBIL 
		set AuditYN = 'Y' 
		where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum 
			and LineKey = @totlinekey and TemplateSeq = @totaddonseq
   
   		/* get next addon for the line's template seq */
   		fetch next from bcTotAddon into @totaddonseq
		end		/* End Total Addon Loop */
   
   	if @openaddoncursor = 1
   		begin
   		close bcTotAddon
   		deallocate bcTotAddon
   		select @openaddoncursor = 0
   		end	
   	end		/* End Non-Contract Processing Loop */
   
bspexit:
   
if @openaddoncursor = 1
	begin
	close bcTotAddon
	deallocate bcTotAddon
	select @openaddoncursor = 0
	end	
if @openitemcursor = 1
   	begin
   	close bcItem
   	deallocate bcItem
   	select @openitemcursor = 0
   	end
   
/* Reset @rcode to one of the special rcodes for logging into bJBCE error log.  The 
  Total Addon process is not interrupted for one of these errors, the addon is simply
  skipped.  It is unlikely that multiple errors will occur but if they do we will 
  record only "One" based upon a priority system.  User should resolve the problem
  and re-initialize this Contract. */
if @taxrcode is not null or @seqitemrcode is not null or @linercode is not null
   	begin
   	select @rcode = isnull(@linercode, isnull(@seqitemrcode, isnull(@taxrcode, 99)))
   	select @msg = case @rcode when @linercode then isnull(@lineerrmsg, 'Error text missing.')
   				when @seqitemrcode then isnull(@seqitemerrmsg, 'Error text missing.')
   				when @taxrcode then isnull(@taxerrmsg, 'Error text missing.') else 'Unknown Error.' end
   	end
   
/* The returned @rcode may be 0 - Success, 
  10 - Line Numbering Failure, 11 - Invalid Seq Item Failure, 12 - Invalid Item TaxCode Failure, 
  99 - Unknown but related to 10, 11, 12 Failure. */
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBTandMProcessTotAddons] TO [public]
GO
