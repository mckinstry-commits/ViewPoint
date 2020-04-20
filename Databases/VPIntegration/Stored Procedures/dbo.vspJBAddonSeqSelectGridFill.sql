SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.vspJBAddonSeqSelectGridFill    Script Date: ******/
CREATE proc [dbo].[vspJBAddonSeqSelectGridFill]
/***********************************************************
* CREATED BY:  TJL 04/17/06 - Issue #28215, 6x Rewrite JBTemplate
* MODIFIED By:  
*
* USAGE:
*	Fills 2nd grid for JBTemplateSeq (Sequences using this Addon) Tab.  
*   To be used by user to select Sequences that the current AddonSeq
*   will be applied against.
*
* INPUT PARAMETERS
*	JBCo, Template, AddonSeq
*
* OUTPUT PARAMETERS
*   @msg      Description or error message
*
* RETURN VALUE
*   0         success
*   1         msg & failure
*****************************************************/
(@jbco bCompany, @template varchar(10), @addonseq int, @msg varchar(255) output)
as
set nocount on
   
declare @rcode integer
   
select @rcode = 0
  
if @jbco is null
	begin
	select @msg = 'JBCo is missing.' 
	select @rcode = 1
	goto vspexit
	end 
if @template is null
	begin
	select @msg = 'Template is missing.' 
	select @rcode = 1
	goto vspexit
	end 
   
/* select the results */
select SelectYN = Case when exists(select 1 from bJBTA with (nolock) where JBCo = @jbco and Template = @template 
							and AddonSeq = @addonseq and Seq = s.Seq) then 'Y' else 'N' end,
	s.Seq, s.Type, s.Description
from bJBTS s with (nolock)
where s.JBCo = @jbco and s.Template = @template and s.Seq < @addonseq
order by s.Seq
   
vspexit:
if @rcode <> 0 select @msg = @msg	--+ char(13) + char(10) + '[vspJBAddonSeqSelectGridFill]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJBAddonSeqSelectGridFill] TO [public]
GO
