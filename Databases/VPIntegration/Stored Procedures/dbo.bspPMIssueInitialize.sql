SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMIssueInitialize    Script Date: 8/28/99 9:35:14 AM ******/
   CREATE proc [dbo].[bspPMIssueInitialize]
    /*************************************
    * CREATED BY    : SAE  12/12/97
    * LAST MODIFIED : SAE  12/12/97
	*					GF 10/30/2008 - expanded desc to 60 characters
	*					GF 09/05/2010 - changed to use function vfDateOnly
	*
    * Pass this a Project and some issue info and it will initialize an ISSUE
    *
    * Pass:
    *       PMCO          PM Company this RFI is in
    *       Project       Project for the RFI
    *       OurFirm	      Our Firm that initiator comes from
    *       Initiator     Valid Contact form OurFirm
    *       Description   Description to initialize
    *       DateInitiated The Date initiated
    * Returns:
    *      NewIssue          New issue number that was initialized
    *      MSG if Error
    * Success returns:
    *	0 on Success, 1 on ERROR
    *
    * Error returns:
   
    *	1 and error message
    **************************************/
(@pmco bCompany, @project bJob, @ourfirm bFirm, @initiator bEmployee, @description bItemDesc,
 @dateinitiated bDate, @newissue bIssue output, @msg varchar(255) output)
as
set nocount on
   
    declare @rcode int, @vendorgroup bGroup
    declare @issue bTrans
   
   
   
    select @rcode = 0
   
    if @pmco is null or @project is null
       begin
        select @msg = 'Missing information!', @rcode = 1
        goto bspexit
       end
   
   select @vendorgroup=h.VendorGroup from bHQCO h with (nolock) 
   join bPMCO p with (nolock) on h.HQCo=p.APCo
   where p.PMCo=@pmco
   
   
   begin transaction
   select @issue=1
   select @issue=isnull(Max(Issue),0)+1 from bPMIM with (nolock) where PMCo=@pmco and Project=@project
   if @issue is null or @issue = 0 select @issue = 1
   -- insert into PMIM
   insert into bPMIM(PMCo, Project, Issue, VendorGroup, FirmNumber,
     		   Initiator, Description, DateInitiated, Status)
   values(@pmco, @project, @issue, @vendorgroup, @ourfirm,
    		   @initiator, substring(@description,1,30), isnull(@dateinitiated,dbo.vfDateOnly()),0)
   if @@rowcount = 0
   	begin
   	select @msg = 'Nothing inserted!', @rcode=1
   	rollback
   	goto bspexit
   	end
   
   select @newissue=@issue
   commit transaction
   
   
   
   
   bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMIssueInitialize] TO [public]
GO
