SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspJBAddItemForChgOrder]
   
/****************************************************************************
* CREATED BY: kb 2/22/00
* MODIFIED By : kb 3/27/00 - added billtype restriction
*		kb 5/22/00 - changed bBillGroup to bBillingGroup
* 		bc 01/07/00 - include Contract in JBIT insert
*  		kb 9/26/1 - issue #14680
*   	kb 2/19/2 - issue #16147
*		TJL 07/24/03 - Issue #19017, Change JCCi.Description field to 60 char
*		TJL 07/24/08 - Issue #128287, JB International Sales Tax
*		TJL 03/24/09 - Issue #132867 - ANSI Null evaluating FALSE instead of TRUE
		AR 11/29/10 - #142278 - removing old style joins replace with ANSI correct form
*
* USAGE: If manually add a change order and the item it corresponds to does
*     not exist as an item on the bill and user wants to add the item this
*     stored proc will do it
*
*  INPUT PARAMETERS
*
* OUTPUT PARAMETERS
*   @msg      error message if error occurs
* RETURN VALUE
*   0         success
*   1         Failure
********************************************************************************************************************/
(@co bCompany,@mth bMonth, @billnum int, @job bJob, @aco bACO, @addYN bYN,
    @msg varchar(255) output)
as

set nocount on

/*generic declares */
declare @rcode int

declare @previtemunits bUnits, @previtemamt bDollar, @previtemretg bDollar,
    @previtemrelretg bDollar, @previtemtax bDollar, @previtemdue bDollar,
    @currcontractamt bDollar, @currcontractunits bUnits, @prevwc bDollar,
    @prevwcunits bUnits, @prevsm bDollar, @prevsmretg bDollar, @prevwcretg bDollar,
    @previtemflag bYN, @prevchgordunits bUnits, @prevchgordamt bDollar, @wc bDollar,
    @prevbillforitem_month bMonth, @prevbillforitem int, @wcunits bUnits, @invdate bDate,
    @wcretg bDollar, @description bItemDesc, @billorigunits bDollar, @billorigamt bDollar,
    @jccium bUM, @taxgroup bGroup, @taxcode bTaxCode, @contractitem bContractItem,
	@itembillgroup bBillingGroup, @acoitem bACOItem, @contract bContract, @billtype char(1),
	@wcretpct bPct,
	--International Sales Tax
	@previtemretgtax bDollar, @previtemrelretgtax bDollar

select @rcode=0

select @taxgroup = TaxGroup 
from bHQCO with (nolock)
where HQCo = @co

select @contract = Contract 
from bJBIN with (nolock)
where JBCo = @co and BillNumber = @billnum and BillMonth = @mth
   
ItemLoop:
select @acoitem = min(ACOItem) 
from JBCX with (nolock)
where JBCo = @co and BillMonth = @mth and BillNumber = @billnum and Job = @job and
	ACO = @aco
while @acoitem is not null
   	begin
	select @contractitem = Item 
	from JCOI with (nolock)
	where JCCo = @co and Job = @job and ACO = @aco and ACOItem = @acoitem
	if @addYN = 'N'
		begin
		if not exists(select 1 from JBIT with (nolock) where JBCo = @co and BillMonth = @mth and
			BillNumber = @billnum and Item = @contractitem)
			begin
			update JBCX set AuditYN = 'N' where JBCo = @co and BillMonth = @mth and
				BillNumber = @billnum and ACO = @aco and Job = @job and ACOItem = @acoitem
			delete from JBCX where JBCo = @co and BillMonth = @mth and
				BillNumber = @billnum and ACO = @aco and Job = @job and ACOItem = @acoitem
			end
		end
	else
		begin
       	if not exists(select 1 from JBIT with (nolock) where JBCo = @co and BillMonth = @mth and BillNumber = @billnum and
   			Item = @contractitem)
   	       	begin
       	   	select @previtemunits = 0, @previtemamt = 0, @previtemretg  = 0,
   	   			@previtemrelretg = 0, @previtemtax = 0, @previtemdue = 0, @previtemflag = 'Y',
   				@prevwc = 0, @prevwcunits = 0, @prevsm = 0, @prevsmretg = 0, @prevwcretg = 0,
   				@prevchgordunits = 0, @prevchgordamt = 0, @wc = 0, @wcunits = 0, @wcretg = 0,
				@previtemretgtax  = 0, @previtemrelretgtax = 0
   
       		select @previtemflag = 'Y'
   	       	select @prevbillforitem_month = max(t.BillMonth)
       		from bJBIT t with (nolock)
			join bJBIN n with (nolock) on t.JBCo = n.JBCo and t.BillNumber = n.BillNumber and
   	       		t.BillMonth = n.BillMonth
			where t.JBCo = @co and n.Contract = @contract and Item = @contractitem 
				and	InvStatus <>'D'  
				and ((t.BillGroup = @itembillgroup) or (@itembillgroup is null and t.BillGroup is null))
          		and ((t.BillMonth = @mth and t.BillNumber < @billnum) or (t.BillMonth < @mth))
   
       		if @prevbillforitem_month is not null
   	      		begin
   	       		select @prevbillforitem = max(t.BillNumber)
   				from bJBIT t with (nolock)
				join bJBIN n with (nolock) on t.JBCo = n.JBCo and t.BillNumber = n.BillNumber
   		      		and t.BillMonth = n.BillMonth
   				where t.JBCo = @co and n.Contract = @contract  and Item = @contractitem
       				and InvStatus <> 'D'
   	       			and((t.BillGroup = @itembillgroup) or (@itembillgroup is null and t.BillGroup is null))
   		      		and t.BillMonth = @prevbillforitem_month
   					and ((t.BillMonth = @mth and t.BillNumber < @billnum) or (t.BillMonth < @mth))
   
         		if @prevbillforitem is null  select @previtemflag = 'N'
   	       		end
       		else
   	       		begin
   		  	    select @previtemflag = 'N'
   		      	end
   
       		if @previtemflag='Y'
   	       		begin
   		      	select @previtemunits = PrevWCUnits + WCUnits, @previtemamt = PrevWC + WC + PrevSM + SM,
   		    		@previtemretg = PrevWCRetg + WCRetg + PrevSMRetg + SMRetg + PrevRetgTax + RetgTax,
					@previtemretgtax  = PrevRetgTax + RetgTax,
					@previtemrelretg = PrevRetgReleased + RetgRel,
					@previtemrelretgtax = PrevRetgTaxRel + RetgTaxRel,
   					@previtemtax = PrevTax + TaxAmount, @previtemdue = PrevDue + AmountDue,
   					@prevwc = PrevWC + WC, @prevwcunits = PrevWCUnits + WCUnits, @prevsm = PrevSM + SM,
   					@prevsmretg = PrevSMRetg + SMRetg, @prevwcretg = PrevWCRetg + WCRetg,
   			        @wc = WC, @wcunits = WCUnits, @wcretg = WCRetg
   				from bJBIS
      			where JBCo = @co and BillMonth = @prevbillforitem_month and BillNumber = @prevbillforitem 
					and Item = @contractitem
          		end
			--#142278
            SELECT  @prevchgordunits = ISNULL(SUM(s.ChgOrderUnits), 0),
                    @prevchgordamt = ISNULL(SUM(s.ChgOrderAmt), 0)
            FROM    dbo.JBIS s WITH ( NOLOCK )
                    JOIN dbo.JBIN n WITH ( NOLOCK ) ON s.BillMonth = n.BillMonth
														AND s.BillNumber = n.BillNumber
            WHERE   s.JBCo = n.JBCo
                    AND s.JBCo = @co
                    AND ( ( s.BillNumber <> @billnum )
                          OR ( s.BillNumber = @billnum
                               AND s.BillMonth <> @mth
                             )
                        )
                    AND s.Item = @contractitem
                    AND n.[Contract] = @contract
                    AND ( ( s.BillMonth = @mth
                            AND s.BillNumber < @billnum
                          )
                          OR ( s.BillMonth < @mth )
                        )
   
       		select @description = case when BillDescription is null then Description else BillDescription end,
   	       		@jccium = UM, @taxcode = TaxCode, @billtype = BillType,
       			@billorigunits = BillOriginalUnits, @billorigamt = BillOriginalAmt,
				@wcretpct = RetainPCT
   			from JCCI with (nolock)
			where JCCo = @co and Contract = @contract and Item = @contractitem
   
			if @billtype = 'T' or @billtype = 'N'
				begin
				goto GetNext
				end
   
			select @currcontractunits = @billorigunits + @prevchgordunits ,
   	   			@currcontractamt = @billorigamt + @prevchgordamt
   
       		insert JBIT (JBCo, BillMonth, BillNumber, Item, Description, UnitsBilled, AmtBilled,
   	       		RetgBilled, RetgTax, RetgRel, RetgTaxRel, Discount, TaxBasis, TaxAmount, AmountDue,
   				PrevUnits, PrevAmt, PrevRetg, PrevRetgTax, PrevRetgReleased, PrevRetgTaxRel,
       		    PrevTax, PrevDue, ARLine, ARRelRetgLine, ARRelRetgCrLine, TaxGroup, TaxCode,
   	       	    CurrContract, ContractUnits, PrevWC, PrevWCUnits, WC, WCUnits,
   				PrevSM, Installed, Purchased, SM, SMRetg, PrevSMRetg, PrevWCRetg,
       		    WCRetPct, WCRetg, BillGroup, Contract, AuditYN)
   			select @co, @mth, @billnum, @contractitem, @description, 0, 0,
   				0, 0, 0, 0, 0, 0, 0, 0,
       		    @previtemunits, @previtemamt, @previtemretg, @previtemretgtax, @previtemrelretg, @previtemrelretgtax,
   	       	    @previtemtax, @previtemdue, null, null, null, @taxgroup, @taxcode,
       		    @currcontractamt,  @currcontractunits, @prevwc, @prevwcunits, 0, 0,
   	       	    @prevsm, 0, 0, 0, 0, @prevsmretg, @prevwcretg, @wcretpct, 0,
       		    @itembillgroup, @contract, 'N'
   
       		if @@rowcount = 0
   	       		begin
   				select @msg='Item was not added.', @rcode = 1
       		    goto bspexit
   	       	    end
       		end
		end
GetNext:
   	select @acoitem = min(ACOItem) 
	from JBCX with (nolock)
	where JBCo = @co and BillMonth = @mth and BillNumber = @billnum
		and Job = @job and ACO = @aco and ACOItem > @acoitem
   	end
   
bspexit:
return @rcode


GO
GRANT EXECUTE ON  [dbo].[bspJBAddItemForChgOrder] TO [public]
GO
