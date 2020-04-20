SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspARDescRecType    Script Date:  ******/
CREATE PROC [dbo].[vspARDescRecType]
/***********************************************************
* CREATED BY:  TJL 01/11/06 - Issue #26138:  6x Rewrite
* MODIFIED By : 
*
* USAGE:
* 	Returns Receivable Types Description
*
* INPUT PARAMETERS
*   AR Company
*   Receivable Type to validate
*
* OUTPUT PARAMETERS
*   @msg      Description
*
* RETURN VALUE
*   0         success
*   1         failure
*****************************************************/
(@arco bCompany = null, @rectype int = null,  @msg varchar(255) output)
as
set nocount on

if @arco is null
	begin
	goto vspexit
	end
if @rectype is null
	begin
	goto vspexit
	end
Else
   	begin
 	select @msg = Description from bARRT with (nolock) where RecType = @rectype and ARCo = @arco
   	end

vspexit:

GO
GRANT EXECUTE ON  [dbo].[vspARDescRecType] TO [public]
GO
