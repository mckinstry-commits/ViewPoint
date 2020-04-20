SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspAPURClearPriorApproval]
   /***************************************************
   *    Created:	MV 01/15/08 - #29702 Unapproved Enhancement
   *
   *    Purpose: Called from APUnappInvRev when a reviewer makes 
   *	changes to data and the HQRG.ActionOnChangedData flag is 'Clear prior approvals'
   *	All approved APUR lines are rolled back
   *
   *    Input:
   *        @apco
   *        @uimth
   *        @uiseq
   *
   *    output:
   *            
   ****************************************************/
   (@apco bCompany, @uimth bMonth, @uiseq int, @rev varchar(3),@whatchange varchar(1))
   
   as
   set nocount on

   declare @rcode int, @reviewer varchar(3), @line int,@approvalseq int,
	@updatememo varchar(max),@opencursor int,@date varchar(25)

   select @rcode = 0, @opencursor = 0, @date = convert(varchar(25),getdate(), 100) 


	--check for approvals to clear
	if exists(select 1 from bAPUR WITH (NOLOCK) where APCo=@apco and UIMth=@uimth 
		and UISeq=@uiseq and Line <> -1 and ApprvdYN='Y' and APTrans is null)
		begin --clear approvals
			declare vcAPURupdate cursor for
			select Reviewer,Line,ApprovalSeq,Memo
				from bAPUR where APCo=@apco and UIMth=@uimth and UISeq=@uiseq 
				and Line <> -1 and ApprvdYN='Y' and APTrans is null
			open vcAPURupdate
			select @opencursor = 1
			APUR_loop:
				fetch next from vcAPURupdate into @reviewer,@line,@approvalseq,@updatememo
				if @@fetch_status <> 0 goto APUR_end
			-- clear approval
			if @whatchange = 'D' -- Data change in APUnappInvRevItems
				Begin
				--prepare Memo for update
				if @updatememo is not null
					begin
					select @updatememo + char(13) + char(10) 
					end
				update bAPUR set ApprvdYN='N',DateApproved = NULL, AmountApproved=NULL,
				Memo = @updatememo + @date + ' Approval was cleared due to changed data by Reviewer: ' + @rev
				where APCo=@apco and UIMth=@uimth and UISeq=@uiseq and Line = @line and Reviewer=@reviewer
					and ApprovalSeq=@approvalseq and ApprvdYN='Y' and APTrans is null
				goto APUR_loop
				end
			if @whatchange = 'A' -- Amount change in APUnappInvItems
				Begin
				--prepare Memo for update
				if @updatememo is not null
					begin
					select @updatememo + char(13) + char(10) 
					end
				update bAPUR set ApprvdYN='N',DateApproved = NULL, AmountApproved=NULL,
				Memo = @updatememo + @date + ' Approval was cleared due to changed amount by Reviewer: ' + @rev
				where APCo=@apco and UIMth=@uimth and UISeq=@uiseq and Line = @line and Reviewer=@reviewer
					and ApprovalSeq=@approvalseq and ApprvdYN='Y' and APTrans is null
				goto APUR_loop
				end
		end
	else
		select @rcode=1 -- nothing to clear
   
	APUR_end:
		if @opencursor = 1
		begin
			close vcAPURupdate
			deallocate vcAPURupdate
			select @opencursor = 0
		end

   Return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPURClearPriorApproval] TO [public]
GO
