SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  procedure [dbo].[vspDMAttachmentTypeIDVal]
	/******************************************************
	* CREATED BY:  MarkH 2/14/08 
	* MODIFIED By: 
	*
	* Usage:	Validates Attachment Type ID against DMAttachmentTypesShared
	*	
	*
	* Input params:
	*	
	*		@attachtypeid int
	*		
	*
	* Output params:
	*	@msg		Code description or error message
	*
	* Return code:
	*	0 = success, 1 = failure
	*******************************************************/
   
   	@attachtypeid int, @msg varchar(100) output

	as 
	set nocount on

	declare @rcode int
   	
	select @rcode = 0

	if @attachtypeid is null
	begin
		select @msg = 'Attachment Type ID required.', @rcode = 1
		goto vspexit
	end

	if exists(select 1 from dbo.DMAttachmentTypesShared (nolock) where AttachmentTypeID = @attachtypeid)
	begin
		select @msg = d.Name from dbo.DMAttachmentTypesShared d (nolock)
		where AttachmentTypeID = @attachtypeid
	end
	else
	begin
		select @msg = 'Attachment Type ID does not exist.', @rcode = 1
	end

	vspexit:
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspDMAttachmentTypeIDVal] TO [public]
GO
