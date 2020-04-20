SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[vspVCSiteAttachmentsVal]
/*************************************
* Created By:	CHS 10/1/2007
* Modified By:	CHS	03/28/08
*
* validates Theme ID number and returns Name from pSiteAttachments
*	
* Pass:
*	Theme ID number
*
* Success returns:
*	0 and Theme name from pSiteAttachments
*
* Error returns:
*	1 and error message
**************************************/
(@siteattachmentid int = null, @sitename varchar(60) = null, @msg varchar(60) = null output)

   as 
   set nocount on

   	declare @rcode int
   	select @rcode = 0
   	
   if @siteattachmentid < 0
   	begin
   		select @msg = '', @rcode = 0
   		goto bspexit
   	end
 
   if @sitename = ''
   	begin
   		select @msg = 'Missing Site ID#/Name', @rcode = 1
   		goto bspexit
   	end

	select @msg = VCSiteAttachments.Name from VCSiteAttachments with (nolock)
		left join VCSites with (nolock) on VCSiteAttachments.SiteID = VCSites.SiteID
		where VCSiteAttachments.SiteAttachmentID = @siteattachmentid and VCSites.Name = @sitename

	if @@rowcount = 0
   		begin
	   		select @msg = 'Not a valid Attachment ID#', @rcode = 1
   		end

   
   bspexit:
   	return @rcode
   
   
   



GO
GRANT EXECUTE ON  [dbo].[vspVCSiteAttachmentsVal] TO [public]
GO
