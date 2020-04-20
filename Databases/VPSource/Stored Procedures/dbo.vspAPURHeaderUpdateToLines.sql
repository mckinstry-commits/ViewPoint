SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspAPURHeaderUpdateToLines]
   /***************************************************************
   *    Created 09/30/09 MV - for issue #135718
   *	Modified:
   *
   *    Purpose: to update changes made to APUR header recs in Unapproved Header
   *			 to APUR line recs. If ApprovalSeq is changed in a -1 header rec
   *			 update it to APUR line recs
   *    
   *    Inputs
   *            @apco
   *            @uimth
   *            @uiseq
   *            @reviewer
   *
   *
   ***************************************************************/
   (@apco bCompany, @uimth bMonth, @uiseq int, @reviewer varchar(20), @approvalseq int,
	 @msg varchar(100)output)
   
   as
   set nocount on
   
	declare @rcode int
	select @rcode = 0

	-- check to see if any Lines exist for the Invoice
    if exists (select * from dbo.bAPUR (nolock) h 
				where  h.APCo = @apco and h.UIMth = @uimth and h.UISeq = @uiseq and Reviewer=@reviewer and Line <> -1)
        begin
		update dbo.APUR set ApprovalSeq=@approvalseq
		where APCo=@apco and UIMth=@uimth and UISeq=@uiseq and Reviewer=@reviewer and Line <> -1
		if @@rowcount = 0 
			begin
			select @msg = 'Approval Seq was not updated to line reviewers. ', @rcode = 1  
			end
        end

return @rcode
GO
GRANT EXECUTE ON  [dbo].[vspAPURHeaderUpdateToLines] TO [public]
GO
