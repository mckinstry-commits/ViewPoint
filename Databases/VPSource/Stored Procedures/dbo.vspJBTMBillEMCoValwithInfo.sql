SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspJBTMBillINCoValwithInfo    Script Date: ******/
CREATE Procedure [dbo].[vspJBTMBillEMCoValwithInfo]
/***********************************************************
* CREATED BY: TJL  05/04/06 - Issue #28227, 6x Rewrite JBTMBillLines
* MODIFIED By : 
* 
*
* USAGE:
* validates EM Company number
* 
* INPUT PARAMETERS
*   EMCo   EM Co to Validate  
*
* OUTPUT PARAMETERS
*   
*	
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/ 
(@emco bCompany = null, @emgroup bGroup output, @msg varchar(60)=null output)
as
   
set nocount on
  
declare @rcode int
select @rcode = 0
   	
if @emco is null
	begin
	select @msg = 'Missing EM Company#', @rcode = 1
	goto vspexit
	end

if not exists(select 1 from EMCO with (nolock) where EMCo = @emco)
	begin
	select @msg = 'Not a valid EM Company', @rcode = 1
	goto vspexit
	end
else
   	begin
	select @msg = Name, @emgroup = EMGroup
	from HQCO with (nolock) 
	where HQCo = @emco
	end

vspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJBTMBillEMCoValwithInfo] TO [public]
GO
