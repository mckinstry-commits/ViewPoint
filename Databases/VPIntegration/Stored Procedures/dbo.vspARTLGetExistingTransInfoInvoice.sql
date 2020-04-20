SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspARTLGetExistingTransInfoInvoice]
/****************************************************************************************************
* CREATED BY  : TJL 10/11/07 - Issue #125729, Return critical values from orig line on Adj/Credit/WO 
* MODIFIED By : TJL 03/11/08 - Issue #127365, Use GLCo/GLAcct from Orig Line on Adjustments and Credits
*		TJL 03/24/09 - Issue #132867 - ANSI Null evaluating FALSE instead of TRUE
*
*
* USAGE:
*	This replaces 5x procedure (bspARBLInsertExistingTrans).  The purpose is to Return
*	various values back to the calling Form (ARInvoiceEntryLines) when an Adjustment, Credit or WriteOff
*	is being setup on a New transaction, back to (ARFinChg) when form is being used to create
*	Finance Charge lines when Customer is set to Finance Charges by Invoice.
*
*	Different from 5x, we are no longer inserting
*	any values into the batch table prematurely (as with bspARBLInsertExistingTrans) and 
*	therefore the form continues to function, in all aspects, as though you are adding a record
*	for the first time. 
*
* NOTE:
*	Applied Transactions require that some values be posted exactly the same as on the original invoice line.
*	This procedure is here to accomplish that.  Many (but not all) of these required values need to be returned
*	to the Form, at this time, for a variety or reasons (Outlined below).  A few could have been inserted at
*	the time of batch validation but rather that have two separate operations to accomplish this, I have 
*	placed/set any additional required values using this procedure as well.
* 
* INPUT PARAMETERS
*   @arco		ARCo 
*   @mth		Mth - Month of Original transaction
*   @artrans	ARTrans - Original transaction to apply against  
*	@arline		ARLine - Original transaction line to apply against else apply line to be added              
*
*
* OUTPUT PARAMETERS 
*	@linetype	Form Required:  LineType or First LineType of any existing lines when specific Line does not exist
*	@item		Form Display and record save:  ContractItem if one exists
*	@material	Form Display and record save:  Material if one exists
*	@linedesc	Form Default:  Line Description
*	@taxgroup	Form Required for Validation TaxCode:  When record gets saved (Required by Batch Validation)
*	@taxcode	Form Display, possibly exposed:  (Required by Batch Validation)
*	@rectype	Not required by Form: (Required by Batch Validation, could be input in Validation)	
*	@jcco		Form Required for Validation ContractItem:  When record gets saved (Required by Batch Validation)
*	@contract   Form Required for Validation ContractItem:	When record gets saved (Required by Batch Validation)
*	@inco		Not required by Form: (Required by Batch Validation, could be input in Validation)
*	@loc		Not required by Form: (Required by Batch Validation, could be input in Validation)
*	@matlgroup	Form Required for Validation Material:  When record gets saved
*	@um			Form Default relative to Material:  Material UM
*	@ECM		Form Default relative to Material:  Material ECM
*
* RETURN VALUE
*   0   Success - Line Found
*	1	Failure - Complete failure.  
*   2   Failure - Conditional failure:  Line not found, this is new Line to be added to existing Invoice
******************************************************************************************************/ 
  
(@arco bCompany, @mth bMonth, @artrans bTrans, @arline smallint, @headertype char(1), @linetype char(1) = null output, 
	@item bContractItem = null output,	@material bMatl = null output, @linedesc bDesc = null output, 
	@taxgroup bGroup = null output, @taxcode bTaxCode = null output, @rectype tinyint = null output, 
	@jcco bCompany = null output, @contract bContract = null output, @inco bCompany = null output, @loc bLoc = null output, 
	@matlgroup bGroup = null output, @um bUM = null output, @ecm bECM = null output, 
	@glco bCompany = null output, @glacct bGLAcct = null output, @errmsg varchar(255) output)
as
set nocount on
declare @rcode int

select @rcode=0

if @arco is null
	begin
	select @errmsg = 'Missing ARCo.', @rcode = 1
	goto vspexit
	end
if @mth is null
	begin
	select @errmsg = 'Missing Transaction Month to apply to.', @rcode = 1
	goto vspexit
	end
if @artrans is null
	begin
	select @errmsg = 'Missing AR Transaction to apply to.', @rcode = 1
	goto vspexit
	end	
if @arline is null
	begin
	select @errmsg = 'Missing AR Transaction Line to apply to.', @rcode = 1
	goto vspexit
	end	

/* Since this is an Apply To action, there are existing lines.  However the input Line value may not
   exist.  If not, we will still return the first LineType of existing lines to be used as a default value
   by the form during initial record add.  */
select top 1 @linetype = LineType, @contract = Contract
from bARTL with (nolock)
where ARCo = @arco and Mth = @mth and ARTrans = @artrans
if @@rowcount = 0
	begin
	select @errmsg = 'No Lines exist for this Invoice Header. This is a bad record.', @rcode = 1
	goto vspexit
	end
else
	begin
	/* Release Retg Line Type conversion */
	select @linetype = case @linetype when 'R' then (case when @contract is null then 'O' else 'C' end) else @linetype end
	end

/* Now check for the existence of this ARLine input by the user. */
if exists(select 1 from bARTL with (nolock)
		where ARCo = @arco and Mth = @mth and ARTrans = @artrans and ARLine = @arline)
	begin
	select @linetype = LineType, @item = Item, @material = Material, @linedesc = Description,
		@taxgroup = TaxGroup, @taxcode = TaxCode, @rectype = RecType, @jcco = JCCo,
		@contract = Contract, @inco = INCo, @loc = Loc, @matlgroup = MatlGroup,
		@um = UM, @ecm = ECM, @glco = GLCo, @glacct = GLAcct
	from bARTL with (nolock)
	where ARCo = @arco and Mth = @mth and ARTrans = @artrans and ARLine = @arline
	if @@rowcount = 0
		begin
		select @errmsg = 'A failure has occurred while reading this Lines values. UNDO and try again.', @rcode = 1
		goto vspexit
		end
	else
		begin
		/* Release Retg Line Type conversion */
		select @linetype = case @linetype when 'R' then (case when @contract is null then 'O' else 'C' end) else @linetype end
		end
	end
else
	begin
	if @headertype in ('C', 'W')
		begin
		/* This particular Line does not exist and cannot be added in ARInvoiceEntry. */
		select @errmsg = 'This line does not exists on Original Invoice. Credits and WriteOffs may not be added '
		select @errmsg = @errmsg + 'as part of this process.  Line must be added directly to Original Invoice.', @rcode = 1
		goto vspexit
		end
	else
		/* This particular Line does not exists but can be added.  Send back special error.  
		   This will notify form of this special condition. */
		begin
		select @rcode = 7
		goto vspexit
		end
	end

vspexit:
if @rcode <> 0 select @errmsg = @errmsg	
return @rcode


GO
GRANT EXECUTE ON  [dbo].[vspARTLGetExistingTransInfoInvoice] TO [public]
GO
