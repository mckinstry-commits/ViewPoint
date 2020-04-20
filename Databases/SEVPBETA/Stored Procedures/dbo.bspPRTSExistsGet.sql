SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPRTSExistsGet    Script Date: 8/28/99 9:35:29 AM ******/
      CREATE        proc [dbo].[bspPRTSExistsGet]
      /********************************************************
      * CREATED BY: 	EN 4/8/03
      * MODIFIED BY:	EN 12/6/04 issue 26410  was not using company # when getting PRTS record count
      *
      * USAGE:
      * 	Returns AbortError if an existing entry is found in bPRTS for the user.
      *  First checks for multiple entries for the user and cleans out all but the latest
      *  because only one is allowed per user.
      *
      * INPUT PARAMETERS:
      *	@co		PR Company
      *	@user	User ID
      *
      * OUTPUT PARAMETERS:
      * 	@sendseq	Send Sequence # if last send was aborted
      *	@prgroup	PR Group used in aborted send
      *	msg		AbortError from bPRTS if there is one
      *
      *
      **********************************************************/
      (@co bCompany, @user bVPUserName, @sendseq int output, @prgroup bGroup output, @msg varchar(255) output)
      as
      set nocount on
     
      declare @rcode int
     
      select @rcode = 0
     
      --if multiple bPRTS entries exist for user, clear out all but the latest
      if (select count(*) from PRTS where UserId=@user and PRCo=@co) > 1 --26410
     	begin
     	delete from bPRTS
     	where UserId=@user and SendSeq <> (select max(SendSeq) from PRTS where UserId=@user)
   		and PRCo=@co
     	end
     
      if (select count(*) from PRTS where UserId=@user and PRCo=@co) = 1 --26410
      	select @sendseq=SendSeq, @prgroup=PRGroup, @msg=isnull(AbortError,'') from bPRTS where UserId=@user and PRCo=@co
      else
     	select @rcode = 1 --return code = 1 if not entry found 
     
     
      bspexit:
      
     	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRTSExistsGet] TO [public]
GO
