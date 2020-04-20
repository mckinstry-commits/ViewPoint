SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/******************************************/
CREATE proc [dbo].[bspINMOInit]
/***************************************
* Created By:	RM 04/08/02
* Modified By:	GP 10/24/08 - Issue 130207, changed @desc from bDesc to bItemDesc.
*
*
*
* usage: used to initialize Material Orders in IN
*
* In:
    	@co 		-INCO
    	@mth		-Batch Month
    	@batchid	-Batch ID
    	@sourcemo	-source Material Order
    	@destmo		-destination Material Order
    	@jcco		-destination JC Company
    	@job		-Destination Job
    	@desc		-Destination Description
*
* out:
* @rcode		-return value
* @msg		-error message
*
***************************************/
(@co bCompany, @mth bMonth, @batchid bBatchID, @sourcemo bMO, @destmo bMO,
 @jcco bCompany,@job bJob, @desc bItemDesc, @orderedby varchar(30), @orderdate bDate,
 @quantitiesYN bYN, @unitpriceYN bYN, @notesYN bYN = 'Y', @msg varchar(255) = null output)
as
set nocount on
    
declare @rcode int, @moitem bItem, @loc bLoc, @matlgroup bGroup, @material bMatl,
		@phasegroup bGroup, @phase bPhase, @jcctype bJCCType, @glco bCompany,
		@glacct bGLAcct, @reqdate bDate, @um bUM, @orderedunits bUnits, @unitprice bUnitCost,
		@ecm bECM, @totalprice bDollar, @taxgroup bGroup, @taxcode bTaxCode, @taxamt bDollar,
		@confirmedunits bUnits, @remainunits bUnits, @posteddate bDate, @addedmth bMonth,
		@addedbatchid bBatchID, @inusemth bMonth, @inusebatchid bBatchID, @status tinyint,
		@batchseq int, @opencursor int

select @rcode = 0, @opencursor = 0

---- INMO Variable Assignment
select @status=o.Status, @addedmth=o.AddedMth, @addedbatchid=o.AddedBatchId,
		@inusemth=o.InUseMth, @inusebatchid=o.InUseBatchId
from bINMO o where o.INCo=@co and o.MO=@sourcemo

select @batchseq = isnull(max(BatchSeq),0) + 1
from INMB where Co=@co and Mth=@mth and BatchId=@batchid

---- insert MO batch header
insert INMB(Co, Mth, BatchId, BatchSeq, BatchTransType, MO, Description, JCCo, Job,
			OrderDate,OrderedBy,Status,Notes)
select @co, @mth, @batchid, @batchseq, 'A', @destmo, @desc, @jcco, @job,
		@orderdate,@orderedby,0,
		case @notesYN when 'Y' then Notes else null end
from bINMO where INCo=@co and MO=@sourcemo

---- declare cursor on INMI for MO items
declare INMICursor cursor for Select i.MOItem, i.Loc, i.MatlGroup, i.Material, i.PhaseGroup,
			i.Phase, i.JCCType, i.GLCo, i.GLAcct, i.ReqDate, i.UM, i.OrderedUnits, i.UnitPrice,
			i.ECM, i.TotalPrice, i.TaxGroup, i.TaxCode, i.TaxAmt, i.PostedDate, i.AddedMth,
			i.AddedBatchId, i.InUseMth, i.InUseBatchId, i.Description 
from INMI i where i.INCo=@co and i.MO=@sourcemo

open INMICursor
select @opencursor = 1

FetchNext:
Fetch Next from INMICursor into @moitem, @loc, @matlgroup, @material, @phasegroup,
			@phase, @jcctype, @glco, @glacct, @reqdate, @um, @orderedunits, @unitprice,
			@ecm, @totalprice, @taxgroup, @taxcode, @taxamt, @posteddate, @addedmth,
			@addedbatchid, @inusemth, @inusebatchid, @desc

if @@fetch_status <> 0 goto INMI_end

select @confirmedunits=0, @remainunits=0

if @unitpriceYN = 'N'
	begin
	exec @rcode = bspINGetDefaultUnitPrice @co, @loc, @material, @matlgroup, @unitprice output, @msg output
   	if @quantitiesYN = 'Y'
		begin
   		select @totalprice = @orderedunits * @unitprice * case @ecm when 'E' then 1 when 'C' then 100 when 'M' then 1000 else 1 end
    	if @rcode <> 0 goto bspexit
		end
    end

if @quantitiesYN = 'N'
	begin
	select @orderedunits=0, @totalprice=0
	end

---- insert INIB row
insert INIB(Co, Mth, BatchId, BatchSeq, MOItem, BatchTransType, Loc, MatlGroup, Material,
		Description, JCCo, Job, PhaseGroup, Phase, JCCType, GLCo, GLAcct, ReqDate, UM,
		OrderedUnits, UnitPrice, ECM, TotalPrice, TaxGroup, TaxCode, TaxAmt, RemainUnits,
		Notes)
select @co, @mth, @batchid, @batchseq, @moitem, 'A', @loc, @matlgroup, @material,
		@desc, @jcco, @job, @phasegroup, @phase, @jcctype, @glco, @glacct, @reqdate, @um,
		@orderedunits, @unitprice, @ecm, @totalprice, @taxgroup, @taxcode, @taxamt, @orderedunits,
		case @notesYN when 'Y' then Notes else null end 
from bINMI where INCo=@co and MO=@sourcemo and MOItem=@moitem


goto FetchNext



INMI_end:
	if @opencursor <> 0
		begin
		close INMICursor
		deallocate INMICursor
		select @opencursor = 0
		end


bspexit:
	if @opencursor <> 0
		begin
		close INMICursor
		deallocate INMICursor
		select @opencursor = 0
		end

	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspINMOInit] TO [public]
GO
