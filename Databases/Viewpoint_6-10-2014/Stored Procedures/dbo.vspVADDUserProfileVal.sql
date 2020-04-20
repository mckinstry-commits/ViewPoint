SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspVADDUserProfileVal    Script Date: 8/28/99 9:33:44 AM ******/
   CREATE  proc [dbo].[vspVADDUserProfileVal]

   /***********************************************************
    * CREATED BY: DANF 05/14/07 - 6.X Recode
    *
    * USAGE:
    * 	Checks whether user is set up in DDUP for Doug
    *
    * INPUT PARAMETERS
    *   username, msg
    *
    * OUTPUT PARAMETERS
    *   @msg      error message
    * RETURN VALUE
    *   0         success
    *   1         failure
    *****************************************************/
   	(@uname bVPUserName=null,
   	 @msg varchar(60) output) as
   
   set nocount on
   declare @rcode integer
   declare @validcnt integer
   select @rcode=0
   begin
   
   
   if not exists(select top 1 1 from DDUP with (nolock) where VPUserName=@uname )
   	begin
			select @msg = 'User name does not exist in VA User Profile!', @rcode = 1
			goto bspexit
   	end
   
   
   bspexit:
     return @rcode
   end

GO
GRANT EXECUTE ON  [dbo].[vspVADDUserProfileVal] TO [public]
GO
