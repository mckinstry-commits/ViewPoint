SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[bspEMAUTemplateVal]
/*************************************
*
* Created:   bc 01/17/00
*		TV 02/11/04 - 23061 added isnulls
*		TJL 11/14/06 - Issue #27821, 6x Rewrite.  Remove StoreProc Name from returned msg.
*
* validates AUTemplate
*
* Pass:
*	EMCO, Auto Usage Template
*
* Success returns:
*	0 and Template Description
*
* Error returns:
*	1 and error message
**************************************/
(@emco bCompany = null, @template varchar(10) = null, @msg varchar(255) output)
as
set nocount on
declare @rcode int
select @rcode = 0

if @emco is null
	begin
	select @msg = 'Missing EM Company.', @rcode = 1
	goto bspexit
	end

if @template is null
	begin
	select @msg = 'Missing Auto Usage Template.', @rcode = 1
	goto bspexit
	end

if @template = 'First'
	begin
	select @msg = 'First Template in EM Company.' + isnull(convert(varchar(3),@emco),'')
	goto bspexit
	end

if @template = 'Last'
	begin
	select @msg = 'Last Template in EM Company.' + isnull(convert(varchar(3),@emco),'')
	goto bspexit
	end

select @msg = Description
from bEMUH
where EMCo = @emco and AUTemplate = @template
if @@rowcount = 0
	begin
	select @msg = 'Not a valid Auto Usage Template.', @rcode = 1
	end
   
bspexit:
if @rcode <> 0 select @msg = isnull(@msg,'')
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMAUTemplateVal] TO [public]
GO
