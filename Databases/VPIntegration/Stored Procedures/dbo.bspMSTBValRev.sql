SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****************************************************/
CREATE procedure [dbo].[bspMSTBValRev]
/*****************************************************************************
* Created By: GG 10/21/00
* Modified: GG 04/17/01 - fixed Rev Breakdown calcs, added call to bspMSValRevBdown - #13061
*			GG 07/11/02 - #13929 - added Hours to bMSEM
*			GF 12/05/2003 - #23205 - check error messages, wrap concatenated values with isnull
*
*
* USAGE:
*   Called by bspMSTBValDist to create Haul Expense and Equipment Revenue
*   distributions when a ticket is posted with EM revenue amount.
*
*   Haul expense associated with 'outside' haulers posted when Hauler Payments invoiced to AP
*
*   Adds/updates entries in bMSEM, bMSRB, and bMSGL.
*
*   Errors in batch added to bHQBE using bspHQBEInsert
*
* INPUT PARAMETERS
*   @msco           MS/IN Co#
*   @mth            Batch month
*   @batchid        Batch ID
*   @seq            Batch Sequence
*   @oldnew         0 = old (use old values from bMSTB, reverse sign on amounts),
*                   1 = new (use current values from bMSTB)
*   @fromloc        Sold from IN Location
*   @saletype       Sale type: 'C'=Customer, 'J'=Job, 'I'=Inventory
*   @matlgroup      Material Group
*   @matlcategory   Material Category
*   @material       Material sold
*   @toco           Sold To Co#
*   @msglco         MS/IN GL Co#
*   @revtotal       Total EM Revenue
*   @mstrans        MS Trans#   (null on new entries)
*   @ticket         Ticket #
*   @saledate       Sale Date
*   @custgroup      Customer Group
*   @customer       Customer
*   @custjob        Customer Job
*   @jcco           JC Co#
*   @job            Job
*   @inco           Sold to IN Co#
*   @toloc          Sold to IN Location
*   @emco           EM Co#
*   @equipment      Equipment
*   @emgroup        EM Group
*   @revcode        Revenue Code
*   @phasegroup     Phase Group
*   @haulphase      Haul Phase
*   @hauljcct       Haul JC Cost Type
*   @prco           PR Co#
*   @employee       Employee
*   @revbasis       Revenue basis (units or time based)
*   @revrate        Revenue rate per unit
*	@hrs			Hours
*
* OUTPUT PARAMETERS
*   @errmsg        error message
*
* RETURN
*   0 = successs, 1 = error
*
*******************************************************************************/
(@msco bCompany = null, @mth bMonth = null, @batchid bBatchID = null, @seq int = null, @oldnew tinyint = null,
 @fromloc bLoc = null, @saletype char(1) = null, @matlgroup bGroup = null, @matlcategory varchar(10) = null,
 @material bMatl = null, @toco bCompany = null, @msglco bCompany = null, @revtotal bDollar = null,
 @mstrans bTrans = null, @ticket bTic = null, @saledate bDate = null, @custgroup bGroup = null,
 @customer bCustomer = null, @custjob varchar(20) = null, @jcco bCompany = null, @job bJob = null,
 @inco bCompany = null, @toloc bLoc = null, @emco bCompany = null, @equipment bEquip = null, @emgroup bGroup = null,
 @revcode bRevCode = null, @phasegroup bGroup = null, @haulphase bPhase = null, @hauljcct bJCCType = null,
 @prco bCompany = null, @employee bEmployee = null, @revbasis bUnits = null, @revrate bUnitCost = null,
 @hrs bHrs = null, @errmsg varchar(255) output)
as
set nocount on
   
declare @rcode int, @errorstart varchar(10), @lmhaulexpequipglacct bGLAcct, @lohaulexpequipglacct bGLAcct,
		@haulexpequipglacct bGLAcct, @lshaulexpequipglacct bGLAcct, @lchaulexpequipglacct bGLAcct, @emglco bCompany,
		@emdept bDept, @category varchar(10), @revum bUM, @revglacct bGLAcct, @rate bDollar, @revtemp varchar(10),
		@tedisc bPct, @totbdownamt bDollar, @bdowncode bRevCode, @bdownrate bDollar, @bdownamt bDollar,
		@glacct bGLAcct, @tcdisc bPct, @arglacct bGLAcct, @apglacct bGLAcct, @errortext varchar(255),
		@lastbdowncode bRevCode, @revtemptype char(1), @disc bPct  
   

select @rcode = 0, @errorstart = 'Seq#' + convert(varchar(6),@seq)

-- get default Haul Expense Account
select @lmhaulexpequipglacct = case @saletype when 'J' then JobHaulExpEquipGLAcct
										  when 'I' then InvHaulExpEquipGLAcct
										  else CustHaulExpEquipGLAcct end
from bINLM with (nolock) where INCo = @msco and Loc = @fromloc
if @@rowcount = 0
	begin
	select @errmsg = 'Missing Location!', @rcode = 1   -- sales location already validated in bspMSTBVal
	goto bspexit
	end

---- get any override for Customer sales by Location and Category
select @lohaulexpequipglacct = null
if @saletype = 'C'
	begin
	select @lohaulexpequipglacct = CustHaulExpEquipGLAcct
	from bINLO with (nolock) 
	where INCo = @msco and Loc = @fromloc and MatlGroup = @matlgroup and Category = @matlcategory
	-- assign Haul Expense Account
	select @haulexpequipglacct = isnull(@lohaulexpequipglacct,@lmhaulexpequipglacct)
	end

----get any override for Job or Inventory sales based on 'sell to' Co#
select @lshaulexpequipglacct = null, @lchaulexpequipglacct = null
if @saletype in ('J','I')
	begin
	select @lshaulexpequipglacct = case @saletype when 'J' then JobHaulExpEquipGLAcct else InvHaulExpEquipGLAcct end
	from bINLS with (nolock) 
	where INCo = @msco and Loc = @fromloc and Co = @toco
	-- get any override based on 'sell to' Co# and Category
	select @lchaulexpequipglacct = case @saletype when 'J' then JobHaulExpEquipGLAcct else InvHaulExpEquipGLAcct end
	from bINLC with (nolock) 
	where INCo = @msco and Loc = @fromloc and Co = @toco and MatlGroup = @matlgroup and Category = @matlcategory
	-- assign Haul Expense Account
	select @haulexpequipglacct = isnull(@lchaulexpequipglacct,isnull(@lshaulexpequipglacct,@lmhaulexpequipglacct))
	end
   
-- validate Haul Expense Account
exec @rcode = bspGLACfPostable @msglco, @haulexpequipglacct, 'I', @errmsg output
if @rcode <> 0
	begin
	select @errortext = @errorstart + ' - Haul Expense for Equipment - ' + isnull(@errmsg,'')
	exec @rcode = dbo.bspHQBEInsert @msco, @mth, @batchid, @errortext, @errmsg output
	goto bspexit
	end
-- Expense debit for equipment revenue total posted in MS/IN GL Co#
update bMSGL set Amount = Amount + @revtotal
where MSCo = @msco and Mth = @mth and BatchId = @batchid and GLCo = @msglco and GLAcct = @haulexpequipglacct
and BatchSeq = @seq and HaulLine = 0 and OldNew = @oldnew
if @@rowcount = 0
	begin
insert bMSGL(MSCo, Mth, BatchId, GLCo, GLAcct, BatchSeq, HaulLine, OldNew, MSTrans, Ticket, SaleDate,
		FromLoc, MatlGroup, Material, SaleType, CustGroup, Customer, CustJob, JCCo, Job, INCo, ToLoc, Amount)
		values(@msco, @mth, @batchid, @msglco, @haulexpequipglacct, @seq, 0, @oldnew, @mstrans, @ticket, @saledate,
		@fromloc, @matlgroup, @material, @saletype, @custgroup, @customer, @custjob, @jcco, @job, @inco, @toloc, @revtotal)
	end
	
---- get EM GL Company
select @emglco = GLCo from bEMCO with (nolock) where EMCo = @emco
if @@rowcount = 0
	begin
	select @errmsg = ' Invalid EM Co# ', @rcode = 1   -- already validated
	goto bspexit
	end
	
---- get Equipment info
select @emdept = Department, @category = Category
from bEMEM with (nolock) where EMCo = @emco and Equipment = @equipment
if @@rowcount = 0
	begin
	select @errmsg = 'Invalid Equipment ', @rcode = 1 -- already validated
	goto bspexit
	end
	
---- get Revenue Code info
select @revum = case Basis when 'H' then TimeUM else WorkUM end
from bEMRC with (nolock) where EMGroup = @emgroup and RevCode = @revcode
if @@rowcount = 0
	begin
	select @errmsg = ' Invalid Revenue Code ', @rcode = 1   -- already validated
	goto bspexit
	end

-- get EM Revenue GL Account for Dept and Revenue Code - may not exist if using Breakdown Codes
set @revglacct = null
select @revglacct = GLAcct
from bEMDR with (nolock) where EMCo = @emco and Department = @emdept and EMGroup = @emgroup and RevCode = @revcode

-- add Equipment Revenue distribution
insert bMSEM(MSCo, Mth, BatchId, EMCo, Equipment, EMGroup, RevCode, SaleType, BatchSeq, HaulLine, OldNew, MSTrans,
		SaleDate, FromLoc, MatlGroup, Material, JCCo, Job, PhaseGroup, Phase, JCCType, CustGroup, Customer,
		INCo, ToLoc, PRCo, Employee, GLCo, GLAcct, UM, Units, RevRate, Amount, Hours)
values(@msco, @mth, @batchid, @emco, @equipment, @emgroup, @revcode, @saletype, @seq, 0, @oldnew, @mstrans,
		@saledate, @fromloc, @matlgroup, @material, @jcco, @job, @phasegroup, @haulphase, @hauljcct, @custgroup, @customer,
		@inco, @toloc, @prco, @employee, @emglco, @revglacct, @revum, @revbasis, @revrate, @revtotal, isnull(@hrs,0))

-- process Equipment Revenue Breakdowns
exec @rcode = dbo.bspMSValRevBdown @msco, @mth, @batchid, @seq, 0, @oldnew, @fromloc, @saletype,
	   @matlgroup, @material, @msglco, @revtotal, @mstrans, @ticket, @saledate, @custgroup, @customer,
	   @custjob, @jcco, @job, @inco, @toloc, @emco, @equipment, @emgroup, @revcode, @revglacct, @emglco,
	   @emdept, @category, @errmsg output



bspexit:
	if @rcode <> 0 select @errmsg = isnull(@errmsg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspMSTBValRev] TO [public]
GO
