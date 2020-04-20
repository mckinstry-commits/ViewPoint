SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspJBTandMAddDetailAddons]

/******************************************************************************************************
* CREATED BY: TJL 08/07/08 - Issue #128962, JB International Sales Tax
* MODIFIED BY:  TJL 08/20/10 - Issue #140764, TaxRate calculations accurate to only 5 decimal places.  Needs to be 6
*				KK  09/30/11 - TK-08355 #142979, Pass in itembillgroup to pass to vspJBTandMAddTotalAddons Restrict by Bill Group when updating. 
*
* USED IN: bspJBTandMAddSeqAddons
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
   	@contract bContract, @item bContractItem, @invdate bDate, @taxgroup bGroup, @taxcode bTaxCode, 
	@date bDate, @discrate bRate, @retpct bPct, @jccimarkuprate bRate, @itembillgroup bBillingGroup, @msg varchar(275) output)
as

set nocount on

declare @rcode int, @addontype char(1), @seqdesc varchar(128), @tempseqgroup int, @markupopt char(1),
	@markuprate numeric(17,6), @addlmarkup bDollar, @newline int, @taxrate bRate, @groupnum int, 
	@totlinekey varchar(100), @detaddonseq int, @detaddonseq2 int, @tempseqitem bContractItem, @totaddonseq2 int
	
   
select @rcode = 0

if @taxcode is not null
   	begin
 	exec bspHQTaxRateGet @taxgroup, @taxcode, @invdate,	@taxrate output, @msg = @msg output
  	end

/************************************ Detail addons Blank record inserts ***********************************/
if exists(select 1 from bJBTA a with (nolock)
   	join bJBTS s with (nolock) on a.JBCo=s.JBCo and a.Template=s.Template and a.AddonSeq=s.Seq
   	where a.JBCo = @co and a.Template = @template and a.Seq = @tempseq
   		and s.Type='D')
   
   	/*If Detail Addon does not exist, Add a 0.00 value line.  Updates will occur 
   	  by JBIJ, JBID, JBIL triggers when user moves off line. */
   	begin	/* Begin Detail Addon Blank record insert loop. */

   	select @detaddonseq = min(AddonSeq) 
   	from bJBTA a with (nolock)
   	join bJBTS s with (nolock) on s.JBCo = a.JBCo and s.Template = a.Template and
           s.Seq = a.AddonSeq 
   	where a.JBCo = @co and a.Template = @template and a.Seq = @tempseq and s.Type = 'D'
   
   	while @detaddonseq is not null
       	begin 	/* Begin Detail Addon Loop */ 
   		if exists (select 1 from bJBIL with (nolock) where JBCo = @co and BillMonth = @billmth 
   			and BillNumber = @billnum and LineKey = @linekey and TemplateSeq = @detaddonseq)
			begin
   			goto NextDetailAddon
			end

   		/* Set Markupopt and MarkupRate values for this Detail Addon Sequence */
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
   		where JBCo = @co and Template = @template and Seq = @detaddonseq
   
       	exec @rcode = bspJBTandMAddLineTwo @co, @billmth, @billnum, @linekey,
           	@template, @detaddonseq, null, @newline output, null, @msg output
    		if @rcode <> 0
   			begin
   			select @msg = 'Failed to retrieve LineNumber and Detail Addon '
   			select @msg = @msg + 'for seq#: ' + convert(varchar(10), @detaddonseq)
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
   	        	Job,PhaseGroup,Phase,@date,Template,@detaddonseq,
   	        	@tempseqgroup,@addontype,@seqdesc,
   				case when @markupopt in ('T', 'X') then @taxgroup else null end,
   	         	case when @markupopt in ('T', 'X') then @taxcode else null end,
   	       		@markupopt,isnull(@markuprate,0),
   				0,@addlmarkup,0,0,0,0,
   	    		NewLine,ReseqYN,LineKey,@tempseqgroup, LineForAddon 
   			from bJBIL 
   			where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and LineKey = @linekey and
   	   			TemplateSeq = @tempseq
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

		/* Detail addons on other Detail Addons Blank record inserts */
		if exists(select 1 from bJBTA a with (nolock)
			join bJBTS s with (nolock) on a.JBCo=s.JBCo and a.Template=s.Template and a.AddonSeq=s.Seq
			where a.JBCo = @co and a.Template = @template and a.Seq = @detaddonseq
				and s.Type='D')
			   
			/*If Detail Addon does not exist, Add a 0.00 value line.  Updates will occur 
			  by JBIJ, JBID, JBIL triggers when user moves off line. */
			begin	/* Begin Detail Addon on other Detail Addons Blank record insert loop. */

			select @detaddonseq2 = min(AddonSeq) 
			from bJBTA a with (nolock)
			join bJBTS s with (nolock) on s.JBCo = a.JBCo and s.Template = a.Template and
				   s.Seq = a.AddonSeq 
			where a.JBCo = @co and a.Template = @template and a.Seq = @detaddonseq and s.Type = 'D'
			   
			while @detaddonseq2 is not null
   				begin 	/* Begin Detail Addon on other Detail Addons Loop */ 
				if exists (select 1 from bJBIL with (nolock) where JBCo = @co and BillMonth = @billmth 
					and BillNumber = @billnum and LineKey = @linekey and TemplateSeq = @detaddonseq2)
					begin
					goto NextDetailAddon2
					end
	 
				/* Set Markupopt and MarkupRate values for this Detail Addon Sequence */
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
				where JBCo = @co and Template = @template and Seq = @detaddonseq2
			   
   				exec @rcode = bspJBTandMAddLineTwo @co, @billmth, @billnum, @linekey,
       				@template, @detaddonseq2, null, @newline output, null, @msg output
					if @rcode <> 0
					begin
					select @msg = 'Failed to retrieve LineNumber and Detail Addon '
					select @msg = @msg + 'for seq#: ' + convert(varchar(10), @detaddonseq2)
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
        				Job,PhaseGroup,Phase,@date,Template,@detaddonseq2,
        				@tempseqgroup,@addontype,@seqdesc,
						case when @markupopt in ('T', 'X') then @taxgroup else null end,
         				case when @markupopt in ('T', 'X') then @taxcode else null end,
       					@markupopt,isnull(@markuprate,0),
						0,@addlmarkup,0,0,0,0,
    					NewLine,ReseqYN,LineKey,@tempseqgroup, LineForAddon 
					from bJBIL 
					where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and LineKey = @linekey and
   						TemplateSeq = @tempseq
					end

				/* It is possible that a Total Addon is applied against a Detail Addon and nothing else. (Neither a
				   Source or Total Addon).  In which case, it must be initialized here. */
				exec @rcode = vspJBTandMAddTotalAddons @co, @billmth, @billnum, @template, @detaddonseq2, @linekey,
					@contract, @item, @invdate, @taxgroup, @taxcode, @date, @discrate, @retpct, @jccimarkuprate,
					@itembillgroup,	@msg output

			NextDetailAddon2:	
				/*get next addon for the line's template seq*/
				select @detaddonseq2 = min(AddonSeq) 
				from bJBTA a with (nolock)
				join bJBTS s with (nolock) on s.JBCo = a.JBCo and s.Template = a.Template and
       				s.Seq = a.AddonSeq 
				where a.JBCo = @co and a.Template = @template and a.Seq = @detaddonseq and s.Type = 'D'
					   and AddonSeq > @detaddonseq2
				if @@rowcount = 0 select @detaddonseq2 = null
		   
				end  /* End Detail Addon on other Detail Addons Loop */
			end

		/* It is possible that a Total Addon is applied against a Detail Addon and nothing else. (Neither a
		   Source or Total Addon).  In which case, it must be initialized here. */
		exec @rcode = vspJBTandMAddTotalAddons @co, @billmth, @billnum, @template, @detaddonseq, @linekey,
			@contract, @item, @invdate, @taxgroup, @taxcode, @date, @discrate, @retpct, @jccimarkuprate,
			@itembillgroup, @msg output
	
   	NextDetailAddon:	
		/*get next addon for the line's template seq*/
   		select @detaddonseq = min(AddonSeq) 
   		from bJBTA a with (nolock)
   		join bJBTS s with (nolock) on s.JBCo = a.JBCo and s.Template = a.Template and
           	s.Seq = a.AddonSeq 
   		where a.JBCo = @co and a.Template = @template and a.Seq = @tempseq and s.Type = 'D'
               and AddonSeq > @detaddonseq
		if @@rowcount = 0 select @detaddonseq = null
   
		end  /* End Detail Addon Loop */
   	end	/* End Detail Addon Blank record insert */

vspexit:

if @rcode <> 0 
   	begin
   	select @msg = 'Detail Addon failed. Delete transaction and lines, resolve error, re-add! - ' + @msg
   	select @msg = @msg	
   	end
   
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJBTandMAddDetailAddons] TO [public]
GO
