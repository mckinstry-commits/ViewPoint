SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.[vspJBDescJBTSSeq]    Script Date:  ******/
CREATE PROC [dbo].[vspJBDescJBTSSeq]
/***********************************************************
* CREATED BY:  TJL 04/17/06 - Issue #28215: 6x Rewrite JBTemplate form
* MODIFIED By : 
*
* USAGE:
* 	Returns JBTS Template Sequence Description
*
* INPUT PARAMETERS
*   JB Company
*   JB Template
*	JB Template Seq
*
* OUTPUT PARAMETERS
*   @msg      Description
*
* RETURN VALUE
*   0         success
*   1         failure
*****************************************************/
(@jbco bCompany = null, @template varchar(10) = null, @seq int = null, @msg varchar(255) output)
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
if @seq is null
	begin
	goto vspexit
	end
Else
   	begin
 	select @msg = s.Description
	from bJBTS s with (nolock) 
	where s.JBCo = @jbco and s.Template = @template and s.Seq = @seq
   	end

vspexit:

GO
GRANT EXECUTE ON  [dbo].[vspJBDescJBTSSeq] TO [public]
GO
