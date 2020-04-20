SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMRevTemplateVal    Script Date: 8/28/99 9:34:31 AM ******/
CREATE procedure [dbo].[bspEMRevTemplateVal]
/*************************************
*
* Modified:   bc 08/09/99
*		TJL 11/14/06 - Issue #27821, 6x Rewrite.  Remove StoreProc Name from returned msg.
*
* validates RevTemplate
*
* Pass:
*	EMCO, RevTemplate
*
* Success returns:
*	0 and Template Description
*
* Error returns:
*	1 and error message
**************************************/
(@emco bCompany = null, @revtemplate varchar(10) = null, @type_flag char(1) = null output, @msg varchar(60) output)
as
set nocount on
declare @rcode int
select @rcode = 0
   
if @emco is null
	begin
	select @msg = 'Missing EM Company.', @rcode = 1
	goto bspexit
	end

if @revtemplate is null
	begin
	select @msg = 'Missing Revenue Template.', @rcode = 1
	goto bspexit
	end
   
select @msg = Description, @type_flag = TypeFlag
from bEMTH
where EMCo = @emco and RevTemplate = @revtemplate
if @@rowcount = 0
	begin
	select @msg = 'Not a valid Revenue Template.', @rcode = 1
	end
   
bspexit:
if @rcode<>0 select @msg=isnull(@msg,'')
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMRevTemplateVal] TO [public]
GO
