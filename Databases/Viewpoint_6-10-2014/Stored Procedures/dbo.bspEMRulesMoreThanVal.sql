SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspEMRulesMoreThanVal    Script Date: 8/28/99 9:32:44 AM ******/
CREATE proc [dbo].[bspEMRulesMoreThanVal]

/******************************************************
* Created By:  bc  07/30/99
* Modified By: bc 01/30/01
*		TV 02/11/04 - 23061 added isnulls
*		TJL  11/14/06 - Issue #28036, remove StoreProc title from errmsg
*
*
* Usage:
* makes sure that the MoreThanHrs value is >= the preceding row's LessThanHrs value
*
*
* Input Parameters
*	EMCo		Need company to retreive Allow posting override flag
* 	RulesTable
*  Sequence    optional
*  MoreThanHrs
*
* Output Parameters
*	@msg		   Error message when appropriate.
*
*
* Return Value
*  0	success
*  1	failure
***************************************************/
   
(@emco bCompany, @rulestable varchar(10), @seq int, @morethanhrs bHrs, @msg varchar(255) output)
   
as
set nocount on
declare @rcode int, @lessthanhrs bHrs
select @rcode = 0
   
if @emco is null
	begin
	select @msg= 'Missing company.', @rcode = 1
	goto bspexit
	end

if @rulestable is null
	begin
	select @msg= 'Missing Rules Table.', @rcode = 1
	goto bspexit
	end

if @morethanhrs < 0
	begin
	select @msg = 'More Than Hrs must be greater than 0.', @rcode = 1
	goto bspexit
	end
   
   
/* if no value has passed in for the sequence then get the highest sequence that has been written to this table thus far */
if @seq is null or @seq = 0
	begin
	select @seq = max(Sequence) 
	from EMUD with (nolock)
	where EMCo = @emco and RulesTable = @rulestable
	end
else
	begin
	select @seq = @seq - 1
	end

/* Get the default */
select @lessthanhrs = LessThanHrs
from EMUD with (nolock)
where EMCo = @emco and RulesTable = @rulestable and @seq > 0 and Sequence = @seq
if @@rowcount <> 0
	begin
	if @lessthanhrs > @morethanhrs
		begin
		select @msg = '"More Than" Hours must be greater than or equal to the "Less Than" Hours of the preceding row.', @rcode = 1
		goto bspexit
		end
	/* if @lessthanhrs <> @morethanhrs
	begin
	select @msg = 'When More Than Hours <> Less Than Hours ' + char(13) + ' it may cause problems in Auto Usage.', @rcode = 1
	goto bspexit
	end*/
	end

bspexit:
if @rcode <> 0 select @msg = isnull(@msg,'') -- + char(13) + char(10) + '[bspEMRulesMoreThanVal]'
return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspEMRulesMoreThanVal] TO [public]
GO
