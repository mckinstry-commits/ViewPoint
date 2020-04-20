SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  proc [dbo].[vspAPCommonInfoGetFor1099]
/********************************************************
* CREATED BY: 	MV 01/27/10 - #136691 validate company and return HQCO phone #
* MODIFIED BY:	              
* USAGE:
* 	validates company number and returns HQCO phone # to the 1099 Download 
*	form's DDFH LoadProc field 
*
* INPUT PARAMETERS:
*	@co			AP Co#
*
* OUTPUT PARAMETERS:
*	@hqcophone HQCO.Phone
*	
* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
**********************************************************/
 (@co bCompany=0,@hqcophone varchar(20) output,@msg varchar(100) output)

  as 
set nocount on
declare @rcode int

select @rcode = 0

-- Validate company number
If not exists(select * from APCO with (nolock)where APCo=@co)
	begin
	select @msg = 'Company# ' + convert(varchar,@co) + ' not setup in AP', @rcode = 1
	goto vspexit
	end

 
-- Get info from HQCO
select  @hqcophone =Phone
from bHQCO with (nolock)
where HQCo = @co 


  
vspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspAPCommonInfoGetFor1099] TO [public]
GO
