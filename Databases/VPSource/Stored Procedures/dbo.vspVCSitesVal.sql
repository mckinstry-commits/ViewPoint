SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[vspVCSitesVal]
/*************************************
* Created By:	CHS 11/13/2007
*
* validates Site ID number and returns Name from pSites
*	
* Pass:
*	Page Site Template ID number
*
* Success returns:
*	0 and Page Site Template name from pPageSiteTemplates
*
* Error returns:
*	1 and error message
**************************************/
(@siteid int = -1, @msg varchar(60) output)
   as 
   set nocount on
   	declare @rcode int
   	select @rcode = 0
   	
   if @siteid < 0
   	begin
   		select @msg = 'Missing Site ID#', @rcode = 1
   		goto bspexit
   	end
   
   if exists(select * from pSites where @siteid = SiteID)
   	begin
   		select @msg = Name from pSites where @siteid = SiteID
   		goto bspexit
   	end

   else
   	begin
	   	select @msg = 'Not a valid Site ID#', @rcode = 1
   	end
   
   bspexit:
   	return @rcode
   



GO
GRANT EXECUTE ON  [dbo].[vspVCSitesVal] TO [public]
GO
