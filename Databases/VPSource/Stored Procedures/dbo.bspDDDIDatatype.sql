SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspDDDIDatatype    Script Date: 8/28/99 9:36:10 AM ******/
   CREATE  proc [dbo].[bspDDDIDatatype]
   /***********************************************************
    * CREATED BY: SE   8/20/96
    * MODIFIED By : SE 8/20/96
    *
    * USAGE:
    * validates that Datatype entered in DDDI is in DDDP
    * pass in DD Datatype from DDDI
    * returns DD Datatype Description or ErrMsg
    *
    * INPUT PARAMETERS
    *   Datatype     Datatype from DDDI 
    * INPUT PARAMETERS
    *   @msg     Error message if invalid, otherwise description
    * RETURN VALUE
    *   0 Success
    *   1 fail
    *****************************************************/ 
   	(@Datatype char(30) = null, @msg varchar(60) output)
   as
   set nocount on
   declare @rcode int
   select @rcode = 0
   
   if @Datatype is null
   	begin
   	select @msg = 'Missing Datatype!', @rcode = 1
   	goto bspexit
   
   	end
   
   select @msg = isnull(Description,'No description') from DDDP
   	where Datatype = @Datatype
   if @@rowcount = 0
   	begin
   	select @msg = 'Datatype not on file in DDDP!', @rcode = 1
   	end
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspDDDIDatatype] TO [public]
GO
