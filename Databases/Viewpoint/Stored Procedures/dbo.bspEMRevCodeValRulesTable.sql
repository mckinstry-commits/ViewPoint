SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspEMRevCodeValRulesTable]
   
   /******************************************************
    * Created By:  TV 04/08/04 23754
    *
    * Usage:
    * Validates Revenue code from EMRC.
    * if HrsPerTimeUM = 0 the throw error.
    *
    *
    * Input Parameters
    *	EMCo		Need company to retreive Allow posting override flag
    * 	EMGroup		EM group for this company
    *	RevCode		Revenue code to validate
    *
    * Output Parameters
    *	
    *  0	success
    *  1	failure
    ***************************************************/
   (@EMGroup bGroup, @RevCode bRevCode, @msg varchar(255) output)
   
   as
   set nocount on
   declare @rcode int, @HrsPerTimeUM bHrs
   select @rcode = 0
   
   
   if @RevCode is null
    	begin
    	select @msg= 'Missing Revenue code', @rcode = 1
    	goto bspexit
    	end
   
   
   --Check to see if the Hours/Time units is not set to 0
   select @msg= Description,@HrsPerTimeUM = HrsPerTimeUM
   from bEMRC 
   where EMGroup = @EMGroup and RevCode = @RevCode
   
   if @@rowcount = 0
    	begin
    	select @msg = 'Revenue code not set up.', @rcode = 1
    	goto bspexit
    	end
   if @HrsPerTimeUM = 0 
   	begin
   	select @msg = 'Revenue code has Hours/Time Units set as 0.'+ char(13) +  'This is not valid with Auto Usage.', @rcode = 1
    	goto bspexit
    	end
   
   
   bspexit:
   	if @rcode<>0 select @msg=isnull(@msg,'')	--+ char(13) + char(10) + '[bspEMRevCodeValRulesTable]'
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMRevCodeValRulesTable] TO [public]
GO
