SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMVal_Meters_AddedChanged    Script Date: 9/17/2001 4:28:19 PM ******/
/****** Object:  Stored Procedure dbo.bspEMVal_Meters_AddedChanged    Script Date: 8/28/99 9:36:16 AM ******/
CREATE      procedure [dbo].[bspEMVal_Meters_AddedChanged]
/***********************************************************
* CREATED BY: JM 5/23/99
* MODIFIED By :  09/17/01 JM - Changed creation method for temp tables from 'select * into' to discrete declaration
*of specific fields. Also changed inserts into temp tables to discrete declaration of fields. 
*Ref Issue 14227.
*JM 6/18/02 - Added 'select @deadchar = null, @deadnum = null' before each exec statement that uses
*@deadchar or @deadnum to make sure value is not inadvertently passed into procedure
*JM 12-23-02 Ref Issue 19731 - Changed Equipment val proc to bspEMEquipValForMeterReadings.
* TV 02/11/04 - 23061 added isnulls 
* TRL 01/26/10 Issue 132064  replaced with new validation procedure 
*
* USAGE:
* 	Called by bspEMVal_Meters_Main to run validation applicable
*	only to Added and Changed records.
*
* INPUT PARAMETERS
*	EMCo        EM Company
*	Month       Month of batch
*	BatchId     Batch ID to validate
*	BatchSeq	Batch Seq to validate
*
* OUTPUT PARAMETERS
*	@errmsg     if something went wrong
*
* RETURN VALUE
*	0   Success
*	1   Failure
*****************************************************/
@co bCompany, @mth bMonth, @batchid bBatchID, @batchseq int, @errmsg varchar(255) output

as

set nocount on

declare @rcode int, @actualdate bDate, @deadchar varchar(255), @deadnum float, @emtrans int, @equipment bEquip,
@errorstart varchar(50), @batchtranstype varchar(1) ,@errtext varchar(255)
 
select @rcode = 0

/* Verify parameters passed in. */
if @co is null
begin
	select @errmsg = 'Missing Batch Company!', @rcode = 1
	goto bspexit
end
if @mth is null
begin
	select @errmsg = 'Missing Batch Month!', @rcode = 1
	goto bspexit
end
if @batchid is null
begin
	select @errmsg = 'Missing BatchID!', @rcode = 1
	goto bspexit
end
if @batchseq is null
begin
	select @errmsg = 'Missing Batch Sequence!', @rcode = 1
	goto bspexit
end

select @equipment = Equipment, @actualdate = MeterReadDate/*ActualDate 132064*/, @emtrans = EMTrans, @batchtranstype  = BatchTransType
from dbo.EMBF with(nolock)
where Co = @co	and Mth = @mth and BatchId = @batchid and BatchSeq = @batchseq

/*JM 12-23-02 Ref Issue 19731 - Changed Equipment val proc to bspEMEquipValForMeterReadings. */
/*132064*/
exec @rcode = dbo.vspEMEquipValForMeterReadings @co, @equipment, @emtrans, @mth, @batchid, @batchseq,@batchtranstype ,@actualdate,
null, null,null, null,null,null,null,

null,null,null,
null,null,null,
null,null,null,

null,null,null,

null,null,null,
null,null,null,
null,null,null,
/*132064*/
@errmsg output
if @rcode = 1
begin
	select @errtext =  'Seq ' + isnull(convert(varchar(9),@batchseq),'') + '- Equipment ' + isnull(@equipment,'') + 
		'-' + isnull(@errmsg,'')
	exec @rcode = dbo.bspHQBEInsert @co, @mth, @batchid, @errtext, @errmsg output
	if @rcode <> 0
	begin
		select @errmsg = isnull(@errtext,'') + '-' + isnull(@errmsg,'')
		goto bspexit
	end
end

bspexit:
	if @rcode<>0 select @errmsg=isnull(@errmsg,'')	
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMVal_Meters_AddedChanged] TO [public]
GO
