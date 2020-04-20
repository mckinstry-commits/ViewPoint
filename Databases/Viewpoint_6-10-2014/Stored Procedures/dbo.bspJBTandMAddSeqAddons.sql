SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspJBTandMAddSeqAddons    Script Date: 8/28/99 9:32:34 AM ******/
CREATE proc [dbo].[bspJBTandMAddSeqAddons]
/******************************************************************************************************
* CREATED BY: kb 6/14/00
* MODIFIED BY: kb 1/30/01 - Issue #11150
*		kb 2/7/01 - Issue #12222
*		kb 6/11/1 - issue #12419
*     	kb 10/10/1 - issue #14875
*   	kb 2/8/2 - issue #16068
*    	kb 5/1/2 - issue #17095
*		TJL 07/01/02 - Issue #17701, Rewrite
*		TJL 01/27/03 - Issue #20090, Total Addons do not always Update when JBIL line deleted
*		TJL 07/31/03 - Issue #21714, Use Markup rate from JCCI if available else use Template markup.
*		TJL 08/25/03 - Issue #20471, Combine Total Addon Values for ALL Items under a single Item
*		TJL 09/20/03 - Issue #22126, Performance mods, added noLocks to this procedure
*		TJL 03/31/04 - Issue #24189, Check for invalid Template Seq Item
*		TJL 05/10/06 - Issue #28227, 6x Rewrite.  Return NULL output in bspJBTandMAddLineTwo call
*						Remove @units as an input, Add @addonaddedyn as output
*		TJL 08/07/08 - Issue #128962, JB International Sales Tax, Rewritten, Refactored
*		KK  10/11/11 - TK-08355 #142979 Pass billgroup to vspJBTandMAddTotalAddons and vspJBTandMAddDetailAddons to update by billgroup
*
*
* USED IN:
*	Used when a JC Transaction is added manually from JBTMBillJCDetail-All Form (bspJBTandMAddJCTrans)
*	Used when a 'S' or 'A' Line is added manually from JBTMBillLines grid. (Form.Addons)
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
   
(@co bCompany,  @billmth bMonth, @billnum int, @template varchar(10), @line int, @msg varchar(275) output)
as

set nocount on

declare @rcode int, @taxgroup bGroup, @taxcode bTaxCode, @contract bContract, @invdate bDate, @tempseq int, 
   	@linekey varchar(100), @date bDate, @item bContractItem, @custgroup bGroup, @customer bCustomer, 
	@retpct bPct, @payterms bPayTerms, @discrate bRate, @jccimarkuprate bRate, @itembillgroup bBillingGroup
    
select @rcode = 0

select @contract = Contract, @invdate = InvDate, @custgroup = CustGroup,
   	   @customer = Customer, @payterms = PayTerms, @itembillgroup = BillGroup
from bJBIN with (nolock)
where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum
   
select @discrate = DiscRate from bHQPT with (nolock) where PayTerms = @payterms
   
select @tempseq = TemplateSeq, @linekey = LineKey, @date = Date, @item = Item
from bJBIL with (nolock)
where JBCo = @co and BillMonth = @billmth and BillNumber = @billnum and Line = @line
   
if @contract is not null
   	begin
   	select @taxgroup = TaxGroup, @taxcode = TaxCode, @retpct = RetainPCT, 
   		@jccimarkuprate = MarkUpRate
   	from bJCCI with (nolock)
   	where JCCo = @co and Contract = @contract and Item = @item
   	end
else
   	begin
   	select @taxgroup = TaxGroup, @taxcode = TaxCode
   	from bARCM with (nolock)
   	where CustGroup = @custgroup and Customer = @customer
   	end
   
/******************************* Detail addons Blank record inserts *********************************/
exec @rcode = vspJBTandMAddDetailAddons @co, @billmth, @billnum, @template, @tempseq, @linekey,
	@contract, @item, @invdate, @taxgroup, @taxcode, @date, @discrate, @retpct, @jccimarkuprate,
	@itembillgroup, @msg output

/************************************ Total addons Blank record inserts ***********************************/
exec @rcode = vspJBTandMAddTotalAddons @co, @billmth, @billnum, @template, @tempseq, @linekey,
	@contract, @item, @invdate, @taxgroup, @taxcode, @date, @discrate, @retpct, @jccimarkuprate,
	@itembillgroup, @msg output

bspexit:

if @rcode <> 0 
   	begin
   	select @msg = @msg
   	end
   
return @rcode
GO
GRANT EXECUTE ON  [dbo].[bspJBTandMAddSeqAddons] TO [public]
GO
