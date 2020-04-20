SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[bspJBSourceVal]
/***********************************************************
 * CREATED BY: bc 08/29/00
 * MODIFIED By :
 * 
 * USAGE:
 * validates the source of a JBID record against it's template sequence
 *
 * INPUT PARAMETERS
 *
 * OUTPUT PARAMETERS
 *   @msg      error message if error occurs otherwise Description of Contract
 * RETURN VALUE
 *   0         success
 *   1         Failure
 *****************************************************/

@jbco bCompany, @source char(2), @template varchar(10), @templateseq int, @msg varchar(255) output

as
set nocount on

declare @rcode int, @apyn bYN, @emyn bYN, @inyn bYN, @jcyn bYN, @msyn bYN, @pryn bYN
select @rcode = 0

select @apyn = APYN, @emyn = EMYN, @inyn = INYN, @jcyn = JCYN, @msyn = MSYN, @pryn = PRYN 
from JBTS
where JBCo = @jbco and Template = @template and Seq = @templateseq

if not (@source = 'AP' and @apyn = 'Y') and
	not (@source = 'EM' and @emyn = 'Y') and
	not (@source = 'IN' and @inyn = 'Y') and
	not (@source = 'JC' and @jcyn = 'Y') and
	not (@source = 'MS' and @msyn = 'Y') and
	not (@source = 'PR' and @pryn = 'Y')
	begin
	select @msg = 'Source (' + isnull(@source,'') + ') is not a valid option for template sequence ' + isnull(convert(varchar(10),@templateseq),''), @rcode = 1
	goto bspexit
	end

bspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBSourceVal] TO [public]
GO
