SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspPROTSchedVal    Script Date: 8/28/99 9:33:32 AM ******/
   CREATE  proc [dbo].[vspPROTSchedVal]
    /***********************************************************
     *
     * Created By : EN 5/02/06 
	 *
	 * Same as bspPROTSchedVal except returns flag to indicate whether shift overrides exist.
     *
     *****************************************************/
   	(@prco bCompany = 0, @otsched tinyint = null, @PROSExists bYN output, @msg varchar(60) output)
   as
   
   set nocount on
   
   declare @rcode int
   
   select @rcode = 0, @PROSExists='N'
   
   if @prco is null
   	begin
   	select @msg = 'Missing PR Company!', @rcode = 1
   	goto vspexit
   	end
   
   if @otsched is null
   	begin
   	select @msg = 'Missing OT Schedule!', @rcode = 1
   	goto vspexit
   	end
   
   select @msg = Description
   	from PROT
   	where PRCo = @prco and OTSched = @otsched 
   if @@rowcount = 0
   	begin
   	select @msg = 'PR Overtime Schedule not on file!', @rcode = 1
   	goto vspexit
   	end

   if exists (select * from PROS where PRCo=@prco and OTSched=@otsched) select @PROSExists = 'Y'
   
   vspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPROTSchedVal] TO [public]
GO
