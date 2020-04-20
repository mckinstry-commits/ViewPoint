SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMDocumentRevVal ******/
   CREATE   proc [dbo].[bspPMDocumentRevVal]
    /*************************************
    * CREATED BY    : GF	09/23/2003
    * LAST MODIFIED : SAE  2/2/98
    * Modified By   : GR   8/4/99   modified to return document/revision description
    * validates looks at the document type to get the document category, then based
    * on the document category it will validate the document/revision against appropriate table.
    *				   GF	09/29/2003 - issue #22495 changed isnull(@rev,'') check to @rev is null
    *				   GF   09/30/2003 - issue #22595 added status and status description to output params
    *
    *
    *  SUBMIT  validates against PMSM
    *  DRAWING validates against PMDG
    *
    *
    * Pass:
    *   PM Company
    *   PM Project
    *	 PM Document Type
    *   Document
    *	 Revision
    *	 Document Description
    * Success returns:
    *	0 
    *
    * Error returns:
    *	1 and error message
    **************************************/
   (@pmco bCompany, @project bProject, @doctype bDocType, @document varchar(10)=null,
    @rev tinyint = null, @documentdesc varchar(60) output, @status varchar(10) output,
    @statusdesc varchar(30) output, @msg varchar(255) output)
   as
   set nocount on
    
   declare @rcode int, @category varchar(10)
    
   select @rcode = 0
    
   if @doctype is null
    	begin
    	select @msg = 'Missing document type!', @rcode = 1
    	goto bspexit
    	end
    
   select @category=DocCategory from bPMDT with (nolock) where DocType = @doctype
   if @@rowcount = 0
   	begin
    	select @msg = 'PM Document type ' + isnull(@doctype,'') + ' not on file!', @rcode = 1
    	goto bspexit
   	end
    
   select @msg='Document not on file!', @rcode=1
   
   if @category='SUBMIT'
   	begin
   	if @rev is null
   		begin
   	 	select @documentdesc=Description, @status=Status, @rcode = 0 from PMSM with (nolock) 
   	 	where PMCo=@pmco and Project=@project and SubmittalType=@doctype and Submittal=@document
   		end
   	else
   		begin
    		select @documentdesc=Description, @status=Status, @rcode = 0 from PMSM with (nolock) 
    		where PMCo=@pmco and Project=@project and SubmittalType=@doctype and Submittal=@document and Rev=@rev
   		end
   	end
   
   if @category='DRAWING'
   	begin
   	if @rev is null
   		begin
    		select @documentdesc=Description, @status=Status, @rcode = 0 from PMDG with (nolock) 
    		where PMCo=@pmco and Project=@project and DrawingType=@doctype and Drawing=@document
   		end
   	else
   		begin
    		select @documentdesc=Description, @status=Status, @rcode = 0 from PMDR with (nolock) 
    		where PMCo=@pmco and Project=@project and DrawingType=@doctype and Drawing=@document and Rev=@rev
   		end
   	end
   
   -- get status description from PMSC
   -- Not always necessary to pass in the status.
   if @status is not null
   	begin
   	select @statusdesc = Description from bPMSC with (nolock) where Status = @status
   	end
    
   
   bspexit:
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMDocumentRevVal] TO [public]
GO
