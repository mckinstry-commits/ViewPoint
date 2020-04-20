SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspVCPageSiteTemplateVal]
/*************************************
* Created By:	CHS 10/2/2007
* Modified By:	CHS	03/28/08
*
* validates Page Site Template ID number and returns Name from pPageSiteTemplates
*	
* Pass:
*	Page Site Template ID number, Site ID number
*
* Success returns:
*	0 and Page Site Template name from pPageSiteTemplates
*
* Error returns:
*	1 and error message
**************************************/
(@pagesitetemplateid int = null, @sitename varchar(60) = null, @msg varchar(60) = null output)
   as 
   set nocount on
   	declare @rcode int
   	select @rcode = 0
   	
   if @pagesitetemplateid < 0
   	begin
   		select @msg = '', @rcode = 0
   		goto bspexit
   	end

   if @sitename < ''
   	begin
   		select @msg = 'Missing Site ID#', @rcode = 1
   		goto bspexit
   	end
   
	select @msg = VCPageSiteTemplates.Name from VCPageSiteTemplates with (nolock)
		left join VCSites with (nolock) on VCPageSiteTemplates.SiteID = VCSites.SiteID
		where VCPageSiteTemplates.PageSiteTemplateID = @pagesitetemplateid and VCSites.Name = @sitename

	if @@rowcount = 0
   		begin
	   		select @msg = 'Not a valid Page Site Template ID#', @rcode = 1
   		end

   
   bspexit:
   	return @rcode
   

GO
GRANT EXECUTE ON  [dbo].[vspVCPageSiteTemplateVal] TO [public]
GO
