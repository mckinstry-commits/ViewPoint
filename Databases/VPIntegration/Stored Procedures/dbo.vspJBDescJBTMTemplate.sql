SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.[vspJBDescJBTMTemplate]    Script Date:  ******/
CREATE PROC [dbo].[vspJBDescJBTMTemplate]
/***********************************************************
* CREATED BY:  TJL 04/17/06 - Issue #28215: 6x Rewrite JBTemplate form
* MODIFIED By : 
*
* USAGE:
* 	Returns JBTM Template Description
*
* INPUT PARAMETERS
*   JB Company
*   JB Template
*
* OUTPUT PARAMETERS
*   @msg      Description
*
* RETURN VALUE
*   0         success
*   1         failure
*****************************************************/
(@jbco bCompany = null, @template varchar(10) = null, @msg varchar(255) output)
as
set nocount on

if @jbco is null
	begin
	goto vspexit
	end
if @template is null
	begin
	goto vspexit
	end
Else
   	begin
 	select @msg = m.Description
	from bJBTM m with (nolock) 
	where m.JBCo = @jbco and m.Template = @template
   	end

vspexit:

GO
GRANT EXECUTE ON  [dbo].[vspJBDescJBTMTemplate] TO [public]
GO
