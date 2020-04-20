SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspJBTMBillINCoValwithInfo    Script Date: ******/
CREATE Procedure [dbo].[vspJBTMBillINCoValwithInfo]
/***********************************************************
* CREATED BY: TJL  05/04/06 - Issue #28227, 6x Rewrite JBTMBillLines
* MODIFIED By : 
* 
*
* USAGE:
* validates IN Company number
* 
* INPUT PARAMETERS
*   INCo   IN Co to Validate  
*
* OUTPUT PARAMETERS
*   
*	
* RETURN VALUE
*   0   success
*   1   fail
*****************************************************/ 
(@inco bCompany = null, @matlgroup bGroup output, @msg varchar(60)=null output)
as
   
set nocount on
  
declare @rcode int
select @rcode = 0
   	
if @inco is null
	begin
	select @msg = 'Missing IN Company#', @rcode = 1
	goto vspexit
	end

if not exists(select 1 from INCO with (nolock) where INCo = @inco)
	begin
	select @msg = 'Not a valid IN Company', @rcode = 1
	goto vspexit
	end
else
   	begin
	select @msg = Name, @matlgroup = MatlGroup
	from HQCO with (nolock) 
	where HQCo = @inco
	end

vspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJBTMBillINCoValwithInfo] TO [public]
GO
