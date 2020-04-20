SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspEMLBAttachWarning]
/*************************************
* warns the user if an attachment is going to be transffered away from it's equipment.
* if the user recieves the message and decides they do not want to separate the attachment from the equipment,
* then they must delete both sequences and reenter the primary equipment.
*
* modified:  bc 05/02/01 - added warning for attachments brought in independently of its
*                          primary equipment.  added input parameter.
*                          when @mode = 1 before_rec_update
*                          when @mode = 2 before_rec_insert
*			 TV 08/25/04 25403 - Changed wording.
*
* this is a warning only.
*
* Pass:
*	EMCo, BatchMth, BatchId, BatchSeq,
*   Attachment's ToJCCo, ToJob, ToLoc
*
* Success returns:
*	0
*
* Error returns:
*	1 and error message
**************************************/
@emco bCompany, @mth bMonth, @batchid bBatchID, @seq int, @equip bEquip,
@tojcco bCompany = null, @tojob bJob = null, @toloc bLoc = null, @mode int, @msg varchar(255) output
   
as

set nocount on

declare @rcode int

declare @attachtoseq int, @key_equip bEquip, @key_tojcco bCompany, @key_tojob bJob, @key_toloc bLoc

select @rcode = 0
select @attachtoseq = null, @key_tojcco = null, @key_tojob = null, @key_toloc = null
   
if @mode = 1
begin
	select @attachtoseq = AttachedToSeq from bEMLB
	where Co = @emco and Mth = @mth and BatchId = @batchid and BatchSeq = @seq
 
	if @attachtoseq is not null and @attachtoseq <> @seq
	begin
		select @key_equip = Equipment, @key_tojcco = ToJCCo, @key_tojob = ToJob, @key_toloc = ToLocation from bEMLB
		where Co = @emco and Mth = @mth and BatchId = @batchid and BatchSeq = @attachtoseq

		if isnull(@key_tojcco,0) <> isnull(@tojcco,0) or isnull(@key_tojob,'') <> isnull(@tojob,'') or isnull(@key_toloc,'') <> isnull(@toloc,'')
		begin
			select @msg = 'Warning!  Attachment ' + convert(varchar(10),@equip) + ' is being transferred to a different destination than equipment ' + convert(varchar(10),@key_equip) + '.', @rcode = 1
			goto bspexit
		end
	end
end
   
-- do a separate warning if an attachment is inserted into a batch independently of its primary piece of equipment
-- TV 08/25/04 25403 - Changed wording.
-- TJL 01/22/07 - EMLocXfer 6x Rewrite:  No longer used.  See Equip validation and Form StdBeforeRecAdd
if @mode = 2
begin
	if exists (select 1 from bEMEM where EMCo = @emco and Equipment = @equip and AttachToEquip is not null)
	begin
		select @msg = 'Warning!  Attachment ' + convert(varchar(10),@equip) + ' will be detached from its primary equipment with this transfer.', @rcode = 1
		goto bspexit
	end
end

bspexit:
	if @rcode<>0 select @msg=@msg			-- + char(13) + char(10) + '[bspEMLBAttachWarning]'
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMLBAttachWarning] TO [public]
GO
