SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspPRUELocalCodeGet]
   (@prco bCompany = null, @state varchar(4) = null, @localdesc1 varchar(20) output,
    @localdesc2 varchar(20) output, @localdesc3 varchar(20) output, @msg varchar(255) = null output)
   as
   set nocount on
   /***********************************************************
   * Created By:   GF 08/28/2001
   * Modified By: EN 3/7/08 - #127081  in declare statements change State declarations to varchar(4)
   *
   * USAGE:
   * Gets the local codes descriptions for display in the PRUnemplEmpl form.
   *
   * INPUT PARAMETERS
   *   prco, state
   *
   * OUTPUT PARAMETERS
   *   LocalCode1 Description
   *   LocalCode2 Description
   *   LocalCode3 Description
   *   msg     description, or error message
   *
   * RETURN VALUE
   *   0         success
   *   1         Failure
   *****************************************************/
   
   declare @rcode int, @localcode1 bLocalCode, @localcode2 bLocalCode, @localcode3 bLocalCode
   
   select @rcode = 0, @localdesc1 = 'Not Used', @localdesc2 = 'Not Used', @localdesc3 = 'Not Used'
   
   -- get local codes from PRSI
   select @localcode1=LocalCode1, @localcode2=LocalCode2, @localcode3=LocalCode3
   from PRSI where PRCo=@prco and State=@state
   if @@rowcount <> 1 goto bspexit
   
   -- get local code descriptions from PRLI
   if isnull(@localcode1,'') <> ''
       begin
       select @localdesc1=Description
       from PRLI where PRCo=@prco and LocalCode=@localcode1
       if @@rowcount = 0 select @localdesc1=@localcode1
       end
   
   if isnull(@localcode2,'') <> ''
       begin
       select @localdesc2=Description
       from PRLI where PRCo=@prco and LocalCode=@localcode2
       if @@rowcount = 0 select @localdesc2=@localcode2
       end
   
   if isnull(@localcode3,'') <> ''
       begin
       select @localdesc1=Description
       from PRLI where PRCo=@prco and LocalCode=@localcode3
       if @@rowcount = 0 select @localdesc3=@localcode3
       end
   
   
   bspexit:
       --if @rcode <> 0 select @msg=@msg + char(13) + char(10) + '[bspPRUELocalCodeGet]'
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRUELocalCodeGet] TO [public]
GO
