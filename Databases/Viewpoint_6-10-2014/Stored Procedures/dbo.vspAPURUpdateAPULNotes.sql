SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspAPURUpdateAPULNotes]
   /***************************************************
   *    Created:	MV 10/31/06 APUnappInvRev 6X recode
   *
   *    Purpose: Update APUL notes from APUnappInvRevItems
   *			  and APUR Memo
   *
   *    Input:
   *        @apco
   *        @uimth
   *        @uiseq
   *        @line
   *        @notes
   *
   *    output:
   *            
   ****************************************************/
   (@apco bCompany, @uimth bMonth, @uiseq int, @line int,@rev varchar(3), @notes varchar(8000)= null, 
    @msg varchar(255) output)
   
   as
   
   if @notes is not null
   begin
   declare @updatenotes varchar(8000)
   
   Update APUL set Notes = @notes
   where APCo = @apco and UIMth = @uimth and UISeq = @uiseq and Line = @line 
   
   Select @updatenotes = isnull(Memo, '') from APUR
   where APCo = @apco and UIMth = @uimth and UISeq = @uiseq and Line = @line
	and Reviewer=@rev
   Update APUR set Memo = @updatenotes + @notes where APCo = @apco and UIMth = @uimth
	and UISeq = @uiseq and Line = @line	and Reviewer=@rev
   end
   Return

GO
GRANT EXECUTE ON  [dbo].[vspAPURUpdateAPULNotes] TO [public]
GO
