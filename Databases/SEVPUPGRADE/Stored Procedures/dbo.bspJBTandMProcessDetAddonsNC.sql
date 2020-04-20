SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJBTandMProcessDetAddonsNC    Script Date: 8/28/99 9:32:34 AM ******/
CREATE proc [dbo].[bspJBTandMProcessDetAddonsNC]
/***********************************************************
* CREATED BY: 	TJL 07/03/02 - Issue #17701
* MODIFIED BY:	TJL 09/10/02 - Issue #17620, Correct Source MarkupOpt when 'U' use Rate * Units
*		TJL 09/20/03 - Issue #22126, Performance mods, added noLocks to this procedure
*		TJL 08/13/08 - Issue #128962, JB International Sales Tax
*		TJL 08/20/10 - Issue #140764, TaxRate calculations accurate to only 5 decimal places.  Needs to be 6
*
*
*
* USED IN:
*	bspJBTandMInit
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
*
*****************************************************/
   
(@co bCompany,  @billmth bMonth, @billnum int, @template varchar(10),
   	@line int, @units bUnits, @msg varchar(255) output)
as

set nocount on

declare @rcode int, @addontype char(1), @seqdesc varchar(128), @tempseqgroup int,
   	@subtotal bDollar, @markupopt char(1), @markuprate numeric(17,6), @addlmarkup bDollar,
   	@newline int, @taxgroup bGroup, @taxcode bTaxCode,  @invdate bDate, @taxrate bRate,
   	@tempseq int, @linekey varchar(100), @custgroup bGroup, @customer bCustomer,
   	@payterms bPayTerms, @discrate bRate, @detaddonseq int, @detaddonseq2 int,
	--International Sales Tax
	@arco bCompany, @arcoinvoicetaxyn bYN, @arcotaxretgyn bYN, @arcosepretgtaxyn bYN,
	@retgsubtotal bDollar
   
select @rcode = 0
   
select @invdate = n.InvDate, @custgroup = n.CustGroup, @customer = n.Customer, @payterms = n.PayTerms,
		@arco = c.ARCo, @arcoinvoicetaxyn = a.InvoiceTax, @arcotaxretgyn = a.TaxRetg, @arcosepretgtaxyn = a.SeparateRetgTax
from bJBIN n with (nolock)
join bJCCO c with (nolock) on c.JCCo = n.JBCo
join bARCO a with (nolock) on a.ARCo = c.ARCo
where n.JBCo = @co and n.BillMonth = @billmth and n.BillNumber = @billnum
   
select @discrate = DiscRate from bHQPT with (nolock) where PayTerms = @payterms
   
select @tempseq = TemplateSeq, @linekey = LineKey
from bJBIL with (nolock) 
where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Line = @line
   
select @taxgroup = TaxGroup, @taxcode = TaxCode 
from bARCM with (nolock)
where CustGroup = @custgroup and Customer = @customer
   
if @taxcode is not null
   	begin
 	exec bspHQTaxRateGet @taxgroup, @taxcode, @invdate,
   	@taxrate output, @msg = @msg output
  	end

/* Detail addons record inserts */
if exists(select 1 from bJBTA a with (nolock) 
   	join bJBTS s with (nolock) on a.JBCo=s.JBCo and a.Template=s.Template and a.AddonSeq=s.Seq
   	where a.JBCo = @co and a.Template = @template and a.Seq = @tempseq
   		and s.Type='D')
   
   	begin	/* Begin Detail Addon record insert loop. */
   	select @detaddonseq = min(a.AddonSeq) 
   	from bJBTA a with (nolock) 
   	join bJBTS s with (nolock) on s.JBCo = a.JBCo and s.Template = a.Template and
		s.Seq = a.AddonSeq 
   	where a.JBCo = @co and a.Template = @template and a.Seq = @tempseq and s.Type = 'D'
   
   	while @detaddonseq is not null
       	begin 	/* Begin Detail Addon Loop */ 
		   
   		select @subtotal = 0, @retgsubtotal = 0

   		/* Set Markupopt and MarkupRate values for this Detail Addon Sequence */
     	select @markupopt = MarkupOpt, 
   			@markuprate = case MarkupOpt
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
   		where JBCo = @co and Template = @template and Seq = @detaddonseq

   		/* Get Totals from those sequence/lines that this addon applies against
   		   and whose sequences are earlier than this addon sequence. */
		select @subtotal = isnull(sum(Total),0), @retgsubtotal = isnull(sum(Retainage),0)  
   		from bJBIL l with (nolock)
   		join bJBTA a with (nolock) on a.JBCo=l.JBCo and a.Template=l.Template and a.Seq=l.TemplateSeq
          	where l.JBCo = @co and l.BillMonth = @billmth and l.BillNumber = @billnum
   			and l.Item is null
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

		if not exists(select top 1 1 from bJBIL with (nolock)
			where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
				and LineKey = @linekey and TemplateSeq = @detaddonseq)
			begin
			/* Insert Detail Addon when non exists. */
       		exec @rcode = bspJBTandMAddLine @co, @billmth, @billnum, @linekey,
           		'Y', @template, @detaddonseq, @newline output, @msg output
	   
			if @rcode <> 0
           		begin
				select @newline  = isnull(max(Line),0)+1 
   				from bJBIL with (nolock) 
   				where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
               		and LineKey = @linekey and LineType <> 'T'
				end
	   
       		insert bJBIL (JBCo,BillMonth,BillNumber,Line,Item,Contract,
           		Job,PhaseGroup,Phase,Date,Template,TemplateSeq,
           		TemplateSeqGroup,LineType,Description,TaxGroup,
           		TaxCode,MarkupOpt,MarkupRate,Basis,MarkupAddl,
        		MarkupTotal,
         		Total,
        		Retainage,
         		Discount,
        		NewLine,ReseqYN,LineKey,TemplateGroupNum,
         		LineForAddon)
			select JBCo, BillMonth,BillNumber,@newline,Item,Contract,
           		Job,PhaseGroup,Phase,Date,Template,@detaddonseq,
           		@tempseqgroup,@addontype,@seqdesc,
   				case when @markupopt in ('T', 'X') then @taxgroup else null end,
				case when @markupopt in ('T', 'X') then @taxcode else null end,
				@markupopt,isnull(@markuprate,0),
				-- basis
   				case when @markupopt in ('T', 'X') then case when @taxcode is null then 0 else @subtotal end 
					else @subtotal end,
				-- addlmarkup
   				isnull(@addlmarkup,0),
   				-- markuptotal
   				isnull(@addlmarkup,0) + case @markupopt when 'D'then 0
					when 'R' then 0
					when 'U' then 0
   					when 'T' then case when @taxcode is null then 0 
						else (@subtotal * isnull(@markuprate,0)) end 
   					when 'X' then case when @taxcode is null then 0 
						else (@subtotal * isnull(@markuprate,0)) end 
   					else (@subtotal * isnull(@markuprate,0)) end,
				-- total
   				case @markupopt when 'D' then 0 
					when 'R' then 0 
					when 'U' then isnull(@addlmarkup,0)
   					when 'T' then case when @taxcode is null then isnull(@addlmarkup,0) 
						else isnull(@addlmarkup,0) + (@subtotal * isnull(@markuprate,0)) end 
   					when 'X' then case when @taxcode is null then isnull(@addlmarkup,0) 
						else isnull(@addlmarkup,0) + (@subtotal * isnull(@markuprate,0)) end 
					else isnull(@addlmarkup,0) + (@subtotal * isnull(@markuprate,0)) end,
        		-- retainage
   				case @markupopt when 'R' then (@subtotal * isnull(@markuprate,0))
					   else 0 end,
				-- discount 
   				case @markupopt when 'D' then (@subtotal * isnull(@markuprate,0))
					   else 0 end,
       			NewLine,ReseqYN,LineKey,@tempseqgroup, LineForAddon 
   			from bJBIL with (nolock) 
   			where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and LineKey = @linekey and
      				TemplateSeq = @tempseq
			end
		else
			begin
			/* Update existing Detail Addons */
			update bJBIL
			set Basis = case when @markupopt in ('T', 'X') then case when @taxcode is null then 0 else @subtotal end 
					else @subtotal end,
				MarkupAddl = isnull(@addlmarkup,0),
				MarkupTotal = isnull(@addlmarkup,0) + case @markupopt when 'D'then 0
					when 'R' then 0
					when 'U' then 0
   					when 'T' then case when @taxcode is null then 0 
						else (@subtotal * isnull(@markuprate,0)) end 
   					when 'X' then case when @taxcode is null then 0 
						else (@subtotal * isnull(@markuprate,0)) end 
   					else (@subtotal * isnull(@markuprate,0)) end,
				Total = case @markupopt when 'D' then 0 
					when 'R' then 0 
					when 'U' then isnull(@addlmarkup,0)
   					when 'T' then case when @taxcode is null then isnull(@addlmarkup,0) 
						else isnull(@addlmarkup,0) + (@subtotal * isnull(@markuprate,0)) end 
   					when 'X' then case when @taxcode is null then isnull(@addlmarkup,0) 
						else isnull(@addlmarkup,0) + (@subtotal * isnull(@markuprate,0)) end 
					else isnull(@addlmarkup,0) + (@subtotal * isnull(@markuprate,0)) end,
				Retainage = case @markupopt when 'R' then (@subtotal * isnull(@markuprate,0))
					   else 0 end,
				Discount = case @markupopt when 'D' then (@subtotal * isnull(@markuprate,0))
					   else 0 end
			where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
				and LineKey = @linekey and TemplateSeq = @detaddonseq
			end

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
   			join bJBTS s with (nolock) on a.JBCo=s.JBCo and a.Template=s.Template and a.AddonSeq=s.Seq
   			where a.JBCo = @co and a.Template = @template and a.Seq = @detaddonseq
   				and s.Type='D')
		   
   			begin	/* Begin Detail Addon against other Detail Addons record insert loop. */
   			select @detaddonseq2 = min(a.AddonSeq) 
   			from bJBTA a with (nolock) 
   			join bJBTS s with (nolock) on s.JBCo = a.JBCo and s.Template = a.Template and
				s.Seq = a.AddonSeq 
   			where a.JBCo = @co and a.Template = @template and a.Seq = @detaddonseq and s.Type = 'D'
		   
   			while @detaddonseq2 is not null
       			begin 	/* Begin Detail Addon against other Detail Addons Loop */ 
				   
   				select @subtotal = 0, @retgsubtotal = 0

   				/* Set Markupopt and MarkupRate values for this Detail Addon Sequence */
     			select @markupopt = MarkupOpt, 
   					@markuprate = case MarkupOpt
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
   				where JBCo = @co and Template = @template and Seq = @detaddonseq2

   				/* Get Totals from those sequence/lines that this addon applies against
   				   and whose sequences are earlier than this addon sequence. */
				select @subtotal = isnull(sum(Total),0), @retgsubtotal = isnull(sum(Retainage),0)  
   				from bJBIL l with (nolock)
   				join bJBTA a with (nolock) on a.JBCo=l.JBCo and a.Template=l.Template and a.Seq=l.TemplateSeq
          			where l.JBCo = @co and l.BillMonth = @billmth and l.BillNumber = @billnum
   					and l.Item is null
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

				if not exists(select top 1 1 from bJBIL with (nolock)
					where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
						and LineKey = @linekey and TemplateSeq = @detaddonseq2)
					begin
					/* Insert Detail Addon when non exists. */
       				exec @rcode = bspJBTandMAddLine @co, @billmth, @billnum, @linekey,
           				'Y', @template, @detaddonseq2, @newline output, @msg output
			   
					if @rcode <> 0
           				begin
						select @newline  = isnull(max(Line),0)+1 
   						from bJBIL with (nolock) 
   						where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
               				and LineKey = @linekey and LineType <> 'T'
						end
			   
       				insert bJBIL (JBCo,BillMonth,BillNumber,Line,Item,Contract,
           				Job,PhaseGroup,Phase,Date,Template,TemplateSeq,
           				TemplateSeqGroup,LineType,Description,TaxGroup,
           				TaxCode,MarkupOpt,MarkupRate,Basis,MarkupAddl,
        				MarkupTotal,
         				Total,
        				Retainage,
         				Discount,
        				NewLine,ReseqYN,LineKey,TemplateGroupNum,
         				LineForAddon)
					select JBCo, BillMonth,BillNumber,@newline,Item,Contract,
           				Job,PhaseGroup,Phase,Date,Template,@detaddonseq2,
           				@tempseqgroup,@addontype,@seqdesc,
   						case when @markupopt in ('T', 'X') then @taxgroup else null end,
						case when @markupopt in ('T', 'X') then @taxcode else null end,
						@markupopt,isnull(@markuprate,0),
						-- basis
   						case when @markupopt in ('T', 'X') then case when @taxcode is null then 0 else @subtotal end 
							else @subtotal end,
						-- addlmarkup
   						isnull(@addlmarkup,0),
   						-- markuptotal
   						isnull(@addlmarkup,0) + case @markupopt when 'D'then 0
							when 'R' then 0
							when 'U' then 0
   							when 'T' then case when @taxcode is null then 0 
								else (@subtotal * isnull(@markuprate,0)) end 
   							when 'X' then case when @taxcode is null then 0 
								else (@subtotal * isnull(@markuprate,0)) end 
   							else (@subtotal * isnull(@markuprate,0)) end,
						-- total
   						case @markupopt when 'D' then 0 
							when 'R' then 0 
							when 'U' then isnull(@addlmarkup,0)
   							when 'T' then case when @taxcode is null then isnull(@addlmarkup,0) 
								else isnull(@addlmarkup,0) + (@subtotal * isnull(@markuprate,0)) end 
   							when 'X' then case when @taxcode is null then isnull(@addlmarkup,0) 
								else isnull(@addlmarkup,0) + (@subtotal * isnull(@markuprate,0)) end 
							else isnull(@addlmarkup,0) + (@subtotal * isnull(@markuprate,0)) end,
        				-- retainage
   						case @markupopt when 'R' then (@subtotal * isnull(@markuprate,0))
							   else 0 end,
						-- discount 
   						case @markupopt when 'D' then (@subtotal * isnull(@markuprate,0))
							   else 0 end,
       					NewLine,ReseqYN,LineKey,@tempseqgroup, LineForAddon 
   					from bJBIL with (nolock) 
   					where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and LineKey = @linekey and
      						TemplateSeq = @tempseq
					end
				else
					begin
					/* Update existing Detail Addons */
					update bJBIL
					set Basis = case when @markupopt in ('T', 'X') then case when @taxcode is null then 0 else @subtotal end 
							else @subtotal end,
						MarkupAddl = isnull(@addlmarkup,0),
						MarkupTotal = isnull(@addlmarkup,0) + case @markupopt when 'D'then 0
							when 'R' then 0
							when 'U' then 0
   							when 'T' then case when @taxcode is null then 0 
								else (@subtotal * isnull(@markuprate,0)) end 
   							when 'X' then case when @taxcode is null then 0 
								else (@subtotal * isnull(@markuprate,0)) end 
   							else (@subtotal * isnull(@markuprate,0)) end,
						Total = case @markupopt when 'D' then 0 
							when 'R' then 0 
							when 'U' then isnull(@addlmarkup,0)
   							when 'T' then case when @taxcode is null then isnull(@addlmarkup,0) 
								else isnull(@addlmarkup,0) + (@subtotal * isnull(@markuprate,0)) end 
   							when 'X' then case when @taxcode is null then isnull(@addlmarkup,0) 
								else isnull(@addlmarkup,0) + (@subtotal * isnull(@markuprate,0)) end 
							else isnull(@addlmarkup,0) + (@subtotal * isnull(@markuprate,0)) end,
						Retainage = case @markupopt when 'R' then (@subtotal * isnull(@markuprate,0))
							   else 0 end,
						Discount = case @markupopt when 'D' then (@subtotal * isnull(@markuprate,0))
							   else 0 end
					where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
						and LineKey = @linekey and TemplateSeq = @detaddonseq2
					end

   			NextDetailAddon2:	
				/*get next addon for the line's template seq*/
   				select @detaddonseq2 = min(AddonSeq) 
   				from bJBTA a with (nolock) 
   				join bJBTS s with (nolock) on s.JBCo = a.JBCo and s.Template = a.Template and
           			s.Seq = a.AddonSeq 
   				where a.JBCo = @co and a.Template = @template and a.Seq = @detaddonseq and s.Type = 'D'
					   and AddonSeq > @detaddonseq2
				if @@rowcount = 0 select @detaddonseq2 = null
				end		/* End Detail Addons against other Detail Addons Loop */
			end

   	NextDetailAddon:	
		/*get next addon for the line's template seq*/
   		select @detaddonseq = min(AddonSeq) 
   		from bJBTA a with (nolock) 
   		join bJBTS s with (nolock) on s.JBCo = a.JBCo and s.Template = a.Template and
           	s.Seq = a.AddonSeq 
   		where a.JBCo = @co and a.Template = @template and a.Seq = @tempseq and s.Type = 'D'
               and AddonSeq > @detaddonseq
		if @@rowcount = 0 select @detaddonseq = null
   
		end  /* Begin Detail Addon Loop */
   	end	/* End Detail Addon Blank record insert */
 
bspexit:
return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspJBTandMProcessDetAddonsNC] TO [public]
GO
