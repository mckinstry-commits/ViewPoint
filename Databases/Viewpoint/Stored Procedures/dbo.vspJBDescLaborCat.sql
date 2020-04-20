SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspJBDescLaborCat    Script Date:  ******/
CREATE PROC [dbo].[vspJBDescLaborCat]
/***********************************************************
* CREATED BY:  TJL 01/11/06 - Issue #28183: 6x Rewrite Labor Categories form (replace bspJBLaborCatgyVal on key)
* MODIFIED By : 
*
* USAGE:
* 	Returns Labor Category Description
*
* INPUT PARAMETERS
*   JB Company
*   Labor Category to validate
*
* OUTPUT PARAMETERS
*   @msg      Description
*
* RETURN VALUE
*   0         success
*   1         failure
*****************************************************/
(@jbco bCompany = null, @laborcat varchar(10) = null,  @msg varchar(255) output)
as
set nocount on

if @jbco is null
	begin
	goto bspexit
	end
if @laborcat is null
	begin
	goto bspexit
	end
Else
   	begin
 	select @msg = Description from bJBLC with (nolock) where JBCo = @jbco and LaborCategory = @laborcat
   	end

bspexit:

GO
GRANT EXECUTE ON  [dbo].[vspJBDescLaborCat] TO [public]
GO
