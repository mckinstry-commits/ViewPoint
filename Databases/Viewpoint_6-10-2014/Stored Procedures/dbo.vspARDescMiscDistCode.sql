SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspARDescMiscDistCode    Script Date:  ******/
CREATE  PROC [dbo].[vspARDescMiscDistCode]
/***********************************************************
* CREATED BY:  TJL 01/13/06 - Issue #26157:  6x Rewrite (replaces bspARMiscDistCodeVal on key)
* MODIFIED By : 
*
* USAGE:
* 	Returns MiscDistCode Description
*
* INPUT PARAMETERS
*   CustGroup  assigned in bHQCO
*   Dist code  to validate
*
* OUTPUT PARAMETERS
*   @msg      Description
*
* RETURN VALUE
*   0         success
*   1         failure
*****************************************************/
(@CustGroup bGroup = null, @miscdistcode char(10) = null, @msg varchar(60) output)
as
set nocount on

declare @rcode int
select @rcode = 0

if @CustGroup is null
	begin
	select @msg = 'Missing Customer Group', @rcode = 1
	goto bspexit
	end
if @miscdistcode is null
	begin
	goto bspexit
	end
Else
   	begin
 	select @msg = Description from bARMC with (nolock) where CustGroup = @CustGroup and MiscDistCode = @miscdistcode
   	end

bspexit:

GO
GRANT EXECUTE ON  [dbo].[vspARDescMiscDistCode] TO [public]
GO
