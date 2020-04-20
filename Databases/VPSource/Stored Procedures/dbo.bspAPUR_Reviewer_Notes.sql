SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspAPUR_Reviewer_Notes]
   /***************************************************
   *    Creted: TV 10/14/02
   *
   *    Purpose: Sync note for Reviewers
   *
   *    Input:
   *        @apco
   *        @uimth
   *        @uiseq
   *        @line
   *        @reviewer
   *        @notes
   *
   *    output:
   *            none so far
   ****************************************************/
   (@apco bCompany, @uimth bMonth, @uiseq int, @line int, @reviewer char(3), @notes varchar(8000)= null, 
    @msg varchar(255) output)
   
   as
   
   if @notes is not null
   begin
   declare @memo varchar(8000)
   
   select @memo = isnull(Memo, '') from APUR
   where APCo = @apco and UIMth = @uimth and UISeq = @uiseq and Line = @line and Reviewer = @reviewer
   
   Update APUR set Memo = @memo + @notes
   where APCo = @apco and UIMth = @uimth and UISeq = @uiseq and Line = @line and Reviewer = @reviewer
   end
   
   
   Return

GO
GRANT EXECUTE ON  [dbo].[bspAPUR_Reviewer_Notes] TO [public]
GO
