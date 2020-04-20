SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspJBProcessGroupVal]
/*************************************
*
* Created:  bc 09/22/99
*		TJL 01/12/07 - Issue #28228, 6x Recode JBTMBills.  Removed Stored Proc name from error msg
*
* validates Process Group
*
* Pass:
*	JBCo, Processs Group, Progress Format, T&M Format
*
* Success returns:
*	0
*
* Error returns:
*	1 and error message
**************************************/
(@jbco bCompany, @proccessgroup varchar(20),
     @progressformat bDesc = null output, @tmformat bDesc = null output, @msg varchar(60) output)
as
set nocount on
declare @rcode int
select @rcode = 0

if @jbco is null
	begin
	select @msg = 'Missing JB Company', @rcode = 1
	goto bspexit
	end

if @proccessgroup is null
	begin
	select @msg = 'Missing process group', @rcode = 1
	goto bspexit
	end

select @msg = Description, @progressformat = ProgressFormat, @tmformat = TMFormat
from bJBPG
where JBCo = @jbco and ProcessGroup = @proccessgroup
if @@rowcount = 0
	begin
	select @msg = 'Not a valid process group', @rcode = 1
	end

bspexit:
if @rcode<>0 select @msg=@msg		-- + char(13) + char(10) + '[bspJBProcessGroupVal]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspJBProcessGroupVal] TO [public]
GO
