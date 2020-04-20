SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[vspAPURUpdateAPUINotes]
   /***************************************************
   *    Created:	MV 10/31/06 APUnappInvRev 6X recode
   *				MV 01/05/09 - #131596 - comment out test code so notes will save
   *
   *    Purpose: Update APUI notes from APUnappInvRev Header
   *					and APUR Memo for the -1 rec.
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
   *            
   ****************************************************/
   (@apco bCompany, @uimth bMonth, @uiseq int, @rev varchar(3),@notes varchar(8000)= null, 
    @msg varchar(255) output)
   
   as
   declare @rcode int
	select @rcode = 0

   if isnull(@notes,'') > ''-- is not null
   begin
   declare @updatenotes varchar(8000)
   
   --------------
--
--select @msg = convert(varchar, @uimth), @rcode = 1
--goto vspexit

-----------------
   
   Update APUI set Notes = @notes
   where APCo = @apco and UIMth = @uimth and UISeq = @uiseq 
   end

	if exists (select 1 from APUR where APCo = @apco and 
		UIMth = @uimth and UISeq = @uiseq and Line = -1 and Reviewer=@rev)
	begin
		select @updatenotes = isnull(Memo, '') from APUR
			where APCo = @apco and UIMth = @uimth and UISeq = @uiseq 
			and Line = -1 and Reviewer=@rev
		update APUR set Memo = @updatenotes + @notes
			where APCo = @apco and UIMth = @uimth and UISeq = @uiseq 
			and Line = -1 and Reviewer=@rev 
	end

------
vspexit:
	Return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPURUpdateAPUINotes] TO [public]
GO
