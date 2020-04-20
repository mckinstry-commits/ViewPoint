SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspJBDescProcessGrp    Script Date:  ******/
CREATE PROC [dbo].[vspJBDescProcessGrp]
/***********************************************************
* CREATED BY:  TJL 01/11/06 - Issue #28054:  6x Rewrite  (replaces bspJBProcessGroupVal on key)
* MODIFIED By : 
*
* USAGE:
* 	Returns Process Group Description
*
* INPUT PARAMETERS
*   JB Company
*   ProcessGroup to validate
*
* OUTPUT PARAMETERS
*   @msg      Description
*
* RETURN VALUE
*   0         success
*   1         failure
*****************************************************/
(@jbco bCompany = null, @processgrp varchar(20) = null,  @msg varchar(255) output)
as
set nocount on

if @jbco is null
	begin
	goto bspexit
	end

if @processgrp is null
	begin
	goto bspexit
	end
Else
   	begin
 	select @msg = Description from bJBPG with (nolock) where JBCo = @jbco and ProcessGroup = @processgrp
   	end

bspexit:

GO
GRANT EXECUTE ON  [dbo].[vspJBDescProcessGrp] TO [public]
GO
