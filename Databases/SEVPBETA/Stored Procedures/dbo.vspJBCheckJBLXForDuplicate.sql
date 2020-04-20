SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[vspJBCheckJBLXForDuplicate]

/*****************************************************************************************************
*
* Created:	TJL 05/30/07- Issue #124217, Check for Duplicate Entries in JBLX for JB LaborCategory Assignments
* Modified:  
*
*
* Pass In:
*	JBCo, Craft, and Class
*
* Success returns:
*	0
*
* Error returns:
*	1 and Error message
*
*******************************************************************************************************/
@jbco bCompany, @inputlaborcatgy bCat, @inputseq int, @craft bCraft = null, @class bClass = null, @msg varchar(255) output
   
as
set nocount on
   
declare @rcode int, @laborcatgy bCat, @seq int

select @rcode = 0

if @jbco is null
	begin
	select @msg = 'JB Company is missing.', @rcode = 1
	goto vspexit
	end
if @inputlaborcatgy is null
	begin
	select @msg = 'JB Labor Category is missing.', @rcode = 1
	goto vspexit
	end

/* Check */
select @laborcatgy = LaborCategory, @seq = Seq
from bJBLX with (nolock)
where JBCo = @jbco and isnull(Craft, '') = isnull(@craft, '') and isnull(Class, '') = isnull(@class, '')
if @laborcatgy is not null
	begin
	if @laborcatgy <> @inputlaborcatgy
		begin
		select @msg = 'This Craft/Class combination already exists for Labor Category ' + @laborcatgy + '.' + char(10) + char(10)
		select @msg = @msg + 'Craft/Class must be unique.', @rcode = 1
		goto vspexit
		end
	else
		if @seq <> @inputseq
			begin
			select @msg = 'This Craft/Class combination already exists for this Labor Category .' + char(10) + char(10)
			select @msg = @msg + 'Craft/Class must be unique.', @rcode = 1
			goto vspexit
			end
	end

vspexit:
return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspJBCheckJBLXForDuplicate] TO [public]
GO
