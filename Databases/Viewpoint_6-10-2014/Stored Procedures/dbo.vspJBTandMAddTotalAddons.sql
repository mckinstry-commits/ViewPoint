SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspJBTandMAddTotalAddons]

/******************************************************************************************************
* CREATED BY: TJL 08/07/08 - Issue #128962, JB International Sales Tax
* MODIFIED BY: TJL 08/20/10 - Issue #140764, TaxRate calculations accurate to only 5 decimal places.  Needs to be 6
*              KK  09/30/11 - TK-08355 #142979, Pass in itembillgroup to Restrict by Bill Group when updating. 
*
* USED IN: vspJBTandMAddDetailAddons
*		   bspJBTandMAddSeqAddons
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
***********************************************************************************************************/
(@co bCompany,  @billmth bMonth, @billnum int, @template varchar(10), @tempseq int, @linekey varchar(100), 
   	@contract bContract, @item bContractItem, @invdate bDate,  @taxgroup bGroup, @taxcode bTaxCode, 
	@date bDate, @discrate bRate, @retpct bPct, @jccimarkuprate bRate, @itembillgroup bBillingGroup, 
	@msg varchar(275) output)
as

set nocount on

declare @rcode int, @addontype char(1), @seqdesc varchar(128), @tempseqgroup int, @markupopt char(1),
	@markuprate numeric(17,6), @addlmarkup bDollar, @newline int, @taxrate bRate, @groupnum int, 
	@totlinekey varchar(100), @totaddonseq int, @tempseqitem bContractItem, @totaddonseq2 int
   
select @rcode = 0

if @taxcode is not null
   	begin
 	exec bspHQTaxRateGet @taxgroup, @taxcode, @invdate,	@taxrate output, @msg = @msg output
  	end

/************************************ Total addons Blank record inserts ***********************************/
if exists(select 1 from bJBTA a with (nolock)
   	join bJBTS s with (nolock) on a.JBCo=s.JBCo and a.Template=s.Template and a.AddonSeq=s.Seq
   	where a.JBCo = @co and a.Template = @template and a.Seq = @tempseq
   		and s.Type='T')
   	begin	/* Begin Total Addon Blank record insert */

   	/*************** First Insert 0.00 value line for Total Addons that will be BROKEN OUT by Item **************/
	/* These sequences that get initialized must be based upon the Source being updated or at least another
	   Total Addon that itself is based upon this Source.  We CANNOT intialize all Total Addons regardless
	   because some Sources may not have value and not yet be initialized and therefore we do not want to show
	   a 0.00 value Total Addon in JBIL without its accompaning Source record.  Don't underestimate this.  I spent
	   a great deal of time in testing to come to some of these conclusions (TJL).  */
   	select @totaddonseq = min(AddonSeq) 
   	from bJBTA a with (nolock)
   	join bJBTS s with (nolock) on s.JBCo = a.JBCo and s.Template = a.Template and s.Seq = a.AddonSeq 
   	where a.JBCo = @co and a.Template = @template and a.Seq = @tempseq and s.Type = 'T'
   		and s.ContractItem is null
 
   	while @totaddonseq is not null
       	begin 	/* Begin Total Addon Loop by Item */ 
   		if exists (select 1 from bJBIL with (nolock)  where JBCo = @co and BillMonth = @billmth 
   			and BillNumber = @billnum and LineType = 'T' and TemplateSeq = @totaddonseq
   			and isnull(Item, '') = isnull(@item, ''))
   		goto NextTotalAddon  
		
   		/* Set Markupopt and MarkupRate values for this Total Addon Sequence */
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
   				when 'S' then case when isnull(@jccimarkuprate,0) <> 0 then
   					case MarkupRate when 0 then @jccimarkuprate else MarkupRate end
   					else MarkupRate end
                	else MarkupRate end,
        	@tempseqgroup = GroupNum, @addlmarkup = AddonAmt,
  			@addontype = Type, @seqdesc = Description
     	from bJBTS with (nolock)
   		where JBCo = @co and Template = @template and Seq = @totaddonseq
   
       	exec @rcode = bspJBTandMGetLineKey @co, null, null,	null, @item, @template, 
   			@totaddonseq, null, null, @groupnum, 'Y', @totlinekey output, @msg output
		if @rcode <> 0
   			begin
   			select @msg = 'Failed to retrieve LineKey and Total Addon '
   			select @msg = @msg + 'for seq#: ' + convert(varchar(10), @totaddonseq)
   			select @msg = @msg + ', has failed.'
   			select @rcode = 1
   			goto vspexit
   			end
   		else
           	begin
   	    	exec @rcode = bspJBTandMAddLineTwo @co, @billmth, @billnum, @totlinekey,
   	        	@template, @totaddonseq, @item, @newline output, null, @msg output
   	 		if @rcode <> 0
   				begin
   				select @msg = 'Failed to retrieve LineNumber and Total Addon '
   				select @msg = @msg + 'for seq#: ' + convert(varchar(10), @totaddonseq)
   				select @msg = @msg + ', has failed.'
   				select @rcode = 1
   				goto vspexit
   				end	
   			else
   				begin
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
   		        	null,null,null,null,Template,@totaddonseq,
   		        	@tempseqgroup,@addontype,@seqdesc,
   					case when @markupopt in ('T', 'X') then @taxgroup else null end,
   		         	case when @markupopt in ('T', 'X') then @taxcode else null end,
   		       		@markupopt,isnull(@markuprate,0),
   					0,@addlmarkup,0,0,0,0,
   		    		null,'N',@totlinekey,@tempseqgroup, null 
   				from bJBIL 
   				where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and LineKey = @linekey and
   		   			TemplateSeq = @tempseq
   				end
   			end  -- End Insert
   
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
   			where a.JBCo = @co and a.Template = @template and a.Seq = @totaddonseq
   				and s.Type='T')
   			begin	/* Begin Total Addon on other Total Addons Blank record insert */

   			select @totaddonseq2 = min(AddonSeq) 
   			from bJBTA a with (nolock)
   			join bJBTS s with (nolock) on s.JBCo = a.JBCo and s.Template = a.Template and s.Seq = a.AddonSeq 
   			where a.JBCo = @co and a.Template = @template and a.Seq = @totaddonseq and s.Type = 'T'
   
   			while @totaddonseq2 is not null
       			begin 	/* Begin Total Addon on other Total Addons Loop by Item */ 
				if exists (select 1 from bJBTS with (nolock) where JBCo = @co and Template = @template 
					and Seq = @totaddonseq2 and Type = 'T' and ContractItem is not null)
					begin
					/* Contract Item is not null on the Total Addon sequence. */
   					select @tempseqitem = ContractItem
					from bJBTS 
   					where JBCo = @co and Template = @template and Seq = @totaddonseq2
   
   					/* Need to check if Template Seq Item is valid for this contract. */
   					if not exists(select 1 from bJCCI with (nolock) 
   							where JCCo = @co and Contract = @contract and Item = @tempseqitem) 
   						begin
   						select @msg = 'The specified Contract Item: ' + @tempseqitem + ', on seq#: '  
   						select @msg = @msg + convert(varchar(10),@totaddonseq2) + ', is invalid for Contract: ' 
   						select @msg = @msg + @contract + ', and the Total Addon was not processed.'
   						select @rcode = 1
   						goto vspexit
   						end
   
   					if exists (select 1 from bJBIL with (nolock) where JBCo = @co and BillMonth = @billmth 
   						and BillNumber = @billnum and LineType = 'T' and TemplateSeq = @totaddonseq2
   						and isnull(Item, '') = isnull(@tempseqitem, ''))

   					goto NextTotalAddon2
   
   					select @taxgroup = TaxGroup, @taxcode = TaxCode, @retpct = RetainPCT,
   						@jccimarkuprate = MarkUpRate
   					from bJCCI with (nolock)
   					where JCCo = @co and Contract = @contract and Item = @tempseqitem
   
   					if @taxcode is not null
   						begin
   						exec bspHQTaxRateGet @taxgroup, @taxcode, @invdate,	@taxrate output, @msg = @msg output
   						end
   
   					select @markupopt = MarkupOpt, 
   						@markuprate = case MarkupOpt
   							when 'T' then case when @taxcode is not null then @taxrate 
   								else MarkupRate end
   							when 'X' then case when @taxcode is not null then @taxrate 
   								else MarkupRate end
   							/* MarkupRate may get changed later by bspJBTandMUpdateSeqAddons. */
   							when 'S' then case when isnull(@jccimarkuprate,0) <> 0 then
   								case MarkupRate when 0 then @jccimarkuprate else MarkupRate end
   								else MarkupRate end
             					else MarkupRate end,
     					@tempseqgroup = GroupNum, @addlmarkup = AddonAmt,
   						@addontype = Type, @seqdesc = Description
					from bJBTS with (nolock)
   					where JBCo = @co and Template = @template and Seq = @totaddonseq2
   
					exec @rcode = bspJBTandMGetLineKey @co, null, null,
       					null, @tempseqitem, @template, @totaddonseq2, null, null,
						@groupnum, 'Y', @totlinekey output, @msg output
					if @rcode <> 0
   						begin
   						select @msg = 'Failed to retrieve LineKey and Total Addon '
   						select @msg = @msg + 'for seq#: ' + convert(varchar(10), @totaddonseq2)
   						select @msg = @msg + ', has failed.'
   						select @rcode = 1
   						goto vspexit
   						end
					else
           				begin
   						/* Since we process these Total Addons after all others above, we need to fit this JBIL record
   						   within the proper order of the existing Total Addons.  Therefore we go get the proper Line
   						   number. */
   						exec @rcode = bspJBTandMAddLineTwo @co, @billmth, @billnum, @totlinekey, @template, 
   							@totaddonseq2, @tempseqitem, @newline output, null, @msg output
   	 					if @rcode <> 0
   							begin
   							select @msg = 'Failed to retrieve LineNumber and Total Addon '
   							select @msg = @msg + 'for seq#: ' + convert(varchar(10), @totaddonseq2)
   							select @msg = @msg + ', has failed.'
   							select @rcode = 1
   							goto vspexit
   							end
   	  					else	
   							begin
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
   		     				select JBCo, BillMonth,BillNumber,@newline,@tempseqitem,Contract,
   		        				null,null,null,null,Template,@totaddonseq2,
   		        				@tempseqgroup,@addontype,@seqdesc,
   								case when @markupopt in ('T','X') then @taxgroup else null end,
   		         				case when @markupopt in ('T','X') then @taxcode else null end,
   		       					@markupopt,isnull(@markuprate,0),
   								0,@addlmarkup,0,0,0,0,
   		    					null,'N',@totlinekey,@tempseqgroup, null 
   							from bJBIL 
   							where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and LineKey = @linekey and
   		   						TemplateSeq = @tempseq
   							end
   						end
					end		/* Contract Item is not null on the Total Addon sequence. */
				else
					begin
					/* Contract Item is null on the Total Addon sequence. */
   					if exists (select 1 from bJBIL with (nolock)  where JBCo = @co and BillMonth = @billmth 
   						and BillNumber = @billnum and LineType = 'T' and TemplateSeq = @totaddonseq2
   						and isnull(Item, '') = isnull(@item, ''))
   					goto NextTotalAddon2
   
   					/* Set Markupopt and MarkupRate values for this Total Addon Sequence */
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
   							when 'S' then case when isnull(@jccimarkuprate,0) <> 0 then
   								case MarkupRate when 0 then @jccimarkuprate else MarkupRate end
   								else MarkupRate end
                				else MarkupRate end,
        				@tempseqgroup = GroupNum, @addlmarkup = AddonAmt,
  						@addontype = Type, @seqdesc = Description
     				from bJBTS with (nolock)
   					where JBCo = @co and Template = @template and Seq = @totaddonseq2
   
       				exec @rcode = bspJBTandMGetLineKey @co, null, null,	null, @item, @template, 
   						@totaddonseq2, null, null, @groupnum, 'Y', @totlinekey output, @msg output
					if @rcode <> 0
   						begin
   						select @msg = 'Failed to retrieve LineKey and Total Addon '
   						select @msg = @msg + 'for seq#: ' + convert(varchar(10), @totaddonseq2)
   						select @msg = @msg + ', has failed.'
   						select @rcode = 1
   						goto vspexit
   						end
   					else
           				begin
   	    				exec @rcode = bspJBTandMAddLineTwo @co, @billmth, @billnum, @totlinekey,
   	        				@template, @totaddonseq2, @item, @newline output, null, @msg output
   	 					if @rcode <> 0
   							begin
   							select @msg = 'Failed to retrieve LineNumber and Total Addon '
   							select @msg = @msg + 'for seq#: ' + convert(varchar(10), @totaddonseq2)
   							select @msg = @msg + ', has failed.'
   							select @rcode = 1
   							goto vspexit
   							end	
   						else
   							begin
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
   		        				null,null,null,null,Template,@totaddonseq2,
   		        				@tempseqgroup,@addontype,@seqdesc,
   								case when @markupopt in ('T', 'X') then @taxgroup else null end,
   		         				case when @markupopt in ('T', 'X') then @taxcode else null end,
   		       					@markupopt,isnull(@markuprate,0),
   								0,@addlmarkup,0,0,0,0,
   		    					null,'N',@totlinekey,@tempseqgroup, null 
   							from bJBIL 
   							where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and LineKey = @linekey and
   		   						TemplateSeq = @tempseq
   							end
   						end  -- End Insert
					end		/* End Contract Item is null on Total Addon sequence */

   			NextTotalAddon2:	
         		/*get next addon for the line's template seq*/
   				select @totaddonseq2 = min(AddonSeq) 
   				from bJBTA a with (nolock)
   				join bJBTS s with (nolock) on s.JBCo = a.JBCo and s.Template = a.Template and s.Seq = a.AddonSeq 
   				where a.JBCo = @co and a.Template = @template and a.Seq = @totaddonseq and s.Type = 'T'
					and a.AddonSeq > @totaddonseq2
				if @@rowcount = 0 select @totaddonseq2 = null
				end		/* Endn Total Addon on other Total Addons Loop by Item */ 
			end		/* End Total Addon on other Total Addons Blank record insert */

   	NextTotalAddon:	
		/*get next addon for the line's template seq*/
   		select @totaddonseq = min(AddonSeq) 
   		from bJBTA a with (nolock)
   		join bJBTS s with (nolock) on s.JBCo = a.JBCo and s.Template = a.Template and	s.Seq = a.AddonSeq 
   		where a.JBCo = @co and a.Template = @template and a.Seq = @tempseq and s.Type = 'T'
               and s.ContractItem is null and a.AddonSeq > @totaddonseq
		if @@rowcount = 0 select @totaddonseq = null
   
		end  /* End Total Addon Loop by Item*/

   	/*************** Next insert 0.00 value line for Total Addons that will be APPLIED TO a specific Item **************/
	select @totaddonseq = min(AddonSeq)
	from bJBTA a with (nolock)
	join bJBTS s with (nolock) on s.JBCo = a.JBCo and s.Template = a.Template and s.Seq = a.AddonSeq 
	where a.JBCo = @co and a.Template = @template and a.Seq = @tempseq and s.Type = 'T'
		and s.ContractItem is not null
   
   	while @totaddonseq is not null
       	begin 	/* Begin Total Addon Loop, combined Item */
   		select @tempseqitem = ContractItem
		from bJBTS with (nolock)
   		where JBCo = @co and Template = @template and Seq = @totaddonseq
   
   		/* Need to check if Template Seq Item is valid for this contract. */
   		if not exists(select 1 from bJCCI with (nolock) 
   				where JCCo = @co and Contract = @contract and Item = @tempseqitem) 
   			begin
   			select @msg = 'The specified Contract Item: ' + @tempseqitem + ', on seq#: '  
   			select @msg = @msg + convert(varchar(10),@totaddonseq) + ', is invalid for Contract: ' 
   			select @msg = @msg + @contract + ', and the Total Addon was not processed.'
   			select @rcode = 1
   			goto vspexit
   			end
   
   		if exists (select 1 from bJBIL with (nolock) where JBCo = @co and BillMonth = @billmth 
   			and BillNumber = @billnum and LineType = 'T' and TemplateSeq = @totaddonseq
   			and isnull(Item, '') = isnull(@tempseqitem, ''))
   		goto NextTotalAddon3

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
				goto NextTotalAddon3
			end	
		end 
		
   		select @taxgroup = TaxGroup, @taxcode = TaxCode, @retpct = RetainPCT,
   			@jccimarkuprate = MarkUpRate
   		from bJCCI with (nolock)
   		where JCCo = @co and Contract = @contract and Item = @tempseqitem
   
   		if @taxcode is not null
   			begin
   			exec bspHQTaxRateGet @taxgroup, @taxcode, @invdate,	@taxrate output, @msg = @msg output
   			end
   
   		select @markupopt = MarkupOpt, 
   			@markuprate = case MarkupOpt
   				when 'T' then case when @taxcode is not null then @taxrate 
   					else MarkupRate end
   				when 'X' then case when @taxcode is not null then @taxrate 
   					else MarkupRate end
   				/* MarkupRate may get changed later by bspJBTandMUpdateSeqAddons. */
   				when 'S' then case when isnull(@jccimarkuprate,0) <> 0 then
   					case MarkupRate when 0 then @jccimarkuprate else MarkupRate end
   					else MarkupRate end
             		else MarkupRate end,
     		@tempseqgroup = GroupNum, @addlmarkup = AddonAmt,
   			@addontype = Type, @seqdesc = Description
		from bJBTS with (nolock)
   		where JBCo = @co and Template = @template and Seq = @totaddonseq
    
		exec @rcode = bspJBTandMGetLineKey @co, null, null,
       		null, @tempseqitem, @template, @totaddonseq, null, null,
			@groupnum, 'Y', @totlinekey output, @msg output
		if @rcode <> 0
   			begin
   			select @msg = 'Failed to retrieve LineKey and Total Addon '
   			select @msg = @msg + 'for seq#: ' + convert(varchar(10), @totaddonseq)
   			select @msg = @msg + ', has failed.'
   			select @rcode = 1
   			goto vspexit
   			end
		else
           	begin
   			/* Since we process these Total Addons after all others above, we need to fit this JBIL record
   			   within the proper order of the existing Total Addons.  Therefore we go get the proper Line
   			   number. */
   			exec @rcode = bspJBTandMAddLineTwo @co, @billmth, @billnum, @totlinekey, @template, 
   				@totaddonseq, @tempseqitem, @newline output, null, @msg output
   	 		if @rcode <> 0
   				begin
   				select @msg = 'Failed to retrieve LineNumber and Total Addon '
   				select @msg = @msg + 'for seq#: ' + convert(varchar(10), @totaddonseq)
   				select @msg = @msg + ', has failed.'
   				select @rcode = 1
   				goto vspexit
   				end
   	  		else	
   				begin		
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
   		     	select JBCo, BillMonth,BillNumber,@newline,@tempseqitem,Contract,
   		        	null,null,null,null,Template,@totaddonseq,
   		        	@tempseqgroup,@addontype,@seqdesc,
   					case when @markupopt in ('T','X') then @taxgroup else null end,
   		         	case when @markupopt in ('T','X') then @taxcode else null end,
   		       		@markupopt,isnull(@markuprate,0),
   					0,@addlmarkup,0,0,0,0,
   		    		null,'N',@totlinekey,@tempseqgroup, null 
   				from bJBIL 
   				where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and LineKey = @linekey and
   		   			TemplateSeq = @tempseq
   				end
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
   			where a.JBCo = @co and a.Template = @template and a.Seq = @totaddonseq
   				and s.Type='T')
   			begin	/* Begin Total Addon on other Total Addons Blank record insert */
   			select @totaddonseq2 = min(AddonSeq)
   			from bJBTA a with (nolock)
   			join bJBTS s with (nolock) on s.JBCo = a.JBCo and s.Template = a.Template and s.Seq = a.AddonSeq 
   			where a.JBCo = @co and a.Template = @template and a.Seq = @totaddonseq and s.Type = 'T'
   				and s.ContractItem is not null
   
   			while @totaddonseq2 is not null
       			begin 	/* Begin Total Addon on other Total Addons Loop, combined Item */
   				select @tempseqitem = ContractItem
				from bJBTS 
   				where JBCo = @co and Template = @template and Seq = @totaddonseq2
   
   				/* Need to check if Template Seq Item is valid for this contract. */
   				if not exists(select 1 from bJCCI with (nolock) 
   						where JCCo = @co and Contract = @contract and Item = @tempseqitem) 
   					begin
   					select @msg = 'The specified Contract Item: ' + @tempseqitem + ', on seq#: '  
   					select @msg = @msg + convert(varchar(10),@totaddonseq2) + ', is invalid for Contract: ' 
   					select @msg = @msg + @contract + ', and the Total Addon was not processed.'
   					select @rcode = 1
   					goto vspexit
   					end
   
   				if exists (select 1 from bJBIL with (nolock) where JBCo = @co and BillMonth = @billmth 
   					and BillNumber = @billnum and LineType = 'T' and TemplateSeq = @totaddonseq2
   					and isnull(Item, '') = isnull(@tempseqitem, ''))

   				goto NextTotalAddon4
   
   				select @taxgroup = TaxGroup, @taxcode = TaxCode, @retpct = RetainPCT,
   					@jccimarkuprate = MarkUpRate
   				from bJCCI with (nolock)
   				where JCCo = @co and Contract = @contract and Item = @tempseqitem
   
   				if @taxcode is not null
   					begin
   					exec bspHQTaxRateGet @taxgroup, @taxcode, @invdate,	@taxrate output, @msg = @msg output
   					end
   
   				select @markupopt = MarkupOpt, 
   					@markuprate = case MarkupOpt
   						when 'T' then case when @taxcode is not null then @taxrate 
   							else MarkupRate end
   						when 'X' then case when @taxcode is not null then @taxrate 
   							else MarkupRate end
   						/* MarkupRate may get changed later by bspJBTandMUpdateSeqAddons. */
   						when 'S' then case when isnull(@jccimarkuprate,0) <> 0 then
   							case MarkupRate when 0 then @jccimarkuprate else MarkupRate end
   							else MarkupRate end
             				else MarkupRate end,
     				@tempseqgroup = GroupNum, @addlmarkup = AddonAmt,
   					@addontype = Type, @seqdesc = Description
				from bJBTS with (nolock)
   				where JBCo = @co and Template = @template and Seq = @totaddonseq2
   
				exec @rcode = bspJBTandMGetLineKey @co, null, null,
       				null, @tempseqitem, @template, @totaddonseq2, null, null,
					@groupnum, 'Y', @totlinekey output, @msg output
				if @rcode <> 0
   					begin
   					select @msg = 'Failed to retrieve LineKey and Total Addon '
   					select @msg = @msg + 'for seq#: ' + convert(varchar(10), @totaddonseq2)
   					select @msg = @msg + ', has failed.'
   					select @rcode = 1
   					goto vspexit
   					end
				else
           			begin
   					/* Since we process these Total Addons after all others above, we need to fit this JBIL record
   					   within the proper order of the existing Total Addons.  Therefore we go get the proper Line
   					   number. */
   					exec @rcode = bspJBTandMAddLineTwo @co, @billmth, @billnum, @totlinekey, @template, 
   						@totaddonseq2, @tempseqitem, @newline output, null, @msg output
   	 				if @rcode <> 0
   						begin
   						select @msg = 'Failed to retrieve LineNumber and Total Addon '
   						select @msg = @msg + 'for seq#: ' + convert(varchar(10), @totaddonseq2)
   						select @msg = @msg + ', has failed.'
   						select @rcode = 1
   						goto vspexit
   						end
   	  				else	
   						begin
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
   		     			select JBCo, BillMonth,BillNumber,@newline,@tempseqitem,Contract,
   		        			null,null,null,null,Template,@totaddonseq2,
   		        			@tempseqgroup,@addontype,@seqdesc,
   							case when @markupopt in ('T','X') then @taxgroup else null end,
   		         			case when @markupopt in ('T','X') then @taxcode else null end,
   		       				@markupopt,isnull(@markuprate,0),
   							0,@addlmarkup,0,0,0,0,
   		    				null,'N',@totlinekey,@tempseqgroup, null 
   						from bJBIL 
   						where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and LineKey = @linekey and
   		   					TemplateSeq = @tempseq
   						end
   					end

   			NextTotalAddon4:
   				select @totaddonseq2 = min(AddonSeq) 
   				from bJBTA a with (nolock)
   				join bJBTS s with (nolock) on s.JBCo = a.JBCo and s.Template = a.Template and s.Seq = a.AddonSeq 
   				where a.JBCo = @co and a.Template = @template and a.Seq = @totaddonseq and s.Type = 'T'
   					and s.ContractItem is not null and a.AddonSeq > @totaddonseq2
		   
				if @@rowcount = 0 select @totaddonseq2 = null
       			end 	/* end Total Addon on other Total Addons Loop, combined Item */ 
			end

   	NextTotalAddon3:
   		select @totaddonseq = min(AddonSeq) 
   		from bJBTA a with (nolock)
   		join bJBTS s with (nolock) on s.JBCo = a.JBCo and s.Template = a.Template and s.Seq = a.AddonSeq 
   		where a.JBCo = @co and a.Template = @template and a.Seq = @tempseq and s.Type = 'T'
   			and s.ContractItem is not null and a.AddonSeq > @totaddonseq
   
		if @@rowcount = 0 select @totaddonseq = null
       	end 	/* end Total Addon Loop, combined Item */ 

   	end	/* End Total Addon Blank record insert */

vspexit:

if @rcode <> 0 
   	begin
   	select @msg = 'Total Addon failed. Delete transaction and lines, resolve error, re-add! - ' + @msg
   	select @msg = @msg	
   	end
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJBTandMAddTotalAddons] TO [public]
GO
