SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[bspPRUEDLCodeGet]
 (@prco bCompany = null, @state varchar(4) = null, @dlcodedesc1 varchar(20) output,
  @dlcodedesc2 varchar(20) output, @msg varchar(255) = null output)
 as
 set nocount on
 /***********************************************************
 * Created By:   GF 05/09/2006
 * Modified By: EN 3/7/08 - #127081  in declare statements change State declarations to varchar(4)
 *
 * USAGE:
 * Gets the dl code descriptions for display in the PRUnemplEmpl form.
 *
 * INPUT PARAMETERS
 *   prco, state
 *
 * OUTPUT PARAMETERS
 *   DLCode1 Description
 *   DLCode2 Description
 *   msg     description, or error message
 *
 * RETURN VALUE
 *   0         success
 *   1         Failure
 *****************************************************/
 
 declare @rcode int, @dlcode1 bEDLCode, @dlcode2 bEDLCode
 
 select @rcode = 0, @dlcodedesc1 = 'Not Used', @dlcodedesc2 = 'Not Used'
 
 -- get local codes from PRSI
 select @dlcode1=DLCode1, @dlcode2=DLCode2
 from PRSI where PRCo=@prco and State=@state
 if @@rowcount <> 1 goto bspexit
 
 -- get local code descriptions from PRLI
 if isnull(@dlcode1,'') <> ''
     begin
     select @dlcodedesc1=Description
     from PRDL where PRCo=@prco and DLCode=@dlcode1
     if @@rowcount = 0 select @dlcodedesc1=@dlcode1
     end
 
 if isnull(@dlcode2,'') <> ''
     begin
     select @dlcodedesc2=Description
     from PRDL where PRCo=@prco and DLCode=@dlcode2
     if @@rowcount = 0 select @dlcodedesc2=@dlcode2
     end




 

bspexit:
	--if @rcode <> 0 select @msg=@msg + char(13) + char(13) + '[bspPRUEDLCodeGet]'
 	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPRUEDLCodeGet] TO [public]
GO
