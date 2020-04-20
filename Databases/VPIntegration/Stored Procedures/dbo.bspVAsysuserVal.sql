SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspVAsysuserVal    Script Date: 8/28/99 9:33:44 AM ******/
   CREATE  proc [dbo].[bspVAsysuserVal]

   /***********************************************************
    * CREATED BY: LM 06/26/96 
    * Modified  DANF 10/02/00 - Added check....
	*			DANF 05/14/07 - 6.X Recode
    *
    * USAGE:
    * 	Checks whether user is set up in sysuser
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
   
   /* Checks for user in sysusers
    *  */

   select @validcnt=count(*) from sys.database_principals where name=@uname
   if @validcnt = 0
   	begin
   	select @msg = 'User not in sysusers!', @rcode = 1
   	goto bspexit
   	end

   select @validcnt=count(*) from DDUP where VPUserName=@uname
   if @validcnt = 0
   	begin
        select @validcnt=count(*) from DDUP where UPPER(VPUserName)=UPPER(@uname)
        if @validcnt > 0
           begin
			select @msg = 'User name already exists in another case!', @rcode = 1
			goto bspexit
           end
   	end
   
   
   bspexit:
     return @rcode
   end

GO
GRANT EXECUTE ON  [dbo].[bspVAsysuserVal] TO [public]
GO
