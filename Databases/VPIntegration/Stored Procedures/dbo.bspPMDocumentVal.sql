SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspPMDocumentVal    Script Date: 8/28/99 9:35:10 AM ******/
   CREATE proc [dbo].[bspPMDocumentVal]
    /*************************************
    * CREATED BY    : SAE  2/2/98
    * LAST MODIFIED : SAE  2/2/98
    * Modified By   : GR   8/4/99   modified to return status and document description
    * validates looks at the document type to get the document category, then based
    * on the document category it will validate the document against appropriate table
    *                 GF  11/25/2000 pull description from PMMM if meeting minutes type
    *				  GF  04/08/2002 - added check for drawing type 'DRAWING'
    *				  GF  10/22/2002 - return description for drawing logs. #19061
    *				  GF 09/23/2003 - return description for test logs.
	*				  GP 04/28/2008 - added @drawingrev ouput parameter for retcategory 'DRAWING' #126934
	*				  GP 12/03/2012 - Added doc category SBTML and SBMTLPCKG
    *
    *
    *  OTHER validates against PMOD
    *  PCO  validates against PMOP
    *  SUBMIT  validates against PMSM
    *  RFI  validates against PMRI
    *  MTG  validates against PMMM
    *  DRAWING validates against PMDG
    *
    *
    * Pass:
    *   PMCompany
    *   PM Project
    *	PM Document Type
    *   Document
    * Returns:
    *   Document Category
    *   Status
    *   Document Description
    *   Status Description
    *	Maximum Revision for Submittals and Drawing logs
    * Success returns:
    *	0 and Description from DocumentType
    *
    * Error returns:
    *	1 and error message
    **************************************/
    (@pmco bCompany, @project bProject, @doctype bDocType, @document varchar(10)=null,
     @retcategory varchar(10) =null output, @status varchar(10) output,
     @documentdesc varchar(60) output, @statusdesc varchar(30) output, @rev tinyint output, 
	 @drawingrev varchar(10) output, @msg varchar(255) output)
    as
    set nocount on
    
    declare @rcode int, @revdescription varchar(60)
    
    select @rcode = 0, @rev = 0
    
    if @doctype is null
    	begin
    	select @msg = 'Missing document type!', @rcode = 1
    	goto bspexit
    	end
    
    select @retcategory=DocCategory from bPMDT with (nolock) where DocType = @doctype
    if @@rowcount = 0
        begin
    	select @msg = 'PM Document type ' + isnull(@doctype,'') + ' not on file!', @rcode = 1
    	goto bspexit
        end
    
    select @msg='Document not on file!', @rcode=1
    if @retcategory='OTHER'
    	select @documentdesc=Description, @status=Status, @rcode=0 from PMOD with (nolock)
    	where PMCo=@pmco and Project=@project and DocType=@doctype and Document=@document
    
    if @retcategory='RFI'
    	select @documentdesc=Subject, @status=Status, @rcode=0 from PMRI with (nolock) 
    	where PMCo=@pmco and Project=@project and RFIType=@doctype and RFI=@document
    
    if @retcategory='PCO'
    	select @documentdesc=Description, @rcode=0 from PMOP with (nolock) 
    	where PMCo=@pmco and Project=@project and PCOType=@doctype and PCO=@document
    
    if @retcategory='SUBMIT'
    	select @documentdesc=Description, @status=Status, @rev=Rev, @rcode=0 from PMSM with (nolock) 
    	where PMCo=@pmco and Project=@project and SubmittalType=@doctype and Submittal=@document
    	and Rev = (select max(Rev) from PMSM with (nolock) where PMCo=@pmco and Project=@project and SubmittalType=@doctype and Submittal=@document)
    
    if @retcategory='MTG'
    	select @documentdesc=Subject, @rcode=0 from PMMM with (nolock)
    	where PMCo=@pmco and Project=@project and MeetingType=@doctype and Meeting=@document
    
    if @retcategory='DRAWING'
		begin
    	select @status=Status, @documentdesc=Description, @rcode=0 from PMDG with (nolock) 
    	where PMCo=@pmco and Project=@project and DrawingType=@doctype and Drawing=@document
----    	if @@rowcount = 1
----    		begin
----    		select @drawingrev = max(Rev) from PMDR with (nolock) 
----    		where PMCo=@pmco and Project=@project and DrawingType=@doctype and Drawing=@document
----   			if @@rowcount <> 0
----   				begin
----   				select @documentdesc = Description from PMDR with (nolock)
----   				where PMCo=@pmco and Project=@project and DrawingType=@doctype and Drawing=@document and Rev=@drawingrev
----   				end
----    		end
		end

    if @retcategory='TEST'
    	select @status=Status, @documentdesc=Description, @rcode=0 from PMTL with (nolock) 
    	where PMCo=@pmco and Project=@project and TestType=@doctype and TestCode=@document
   
    if @retcategory='INSPECT'
    	select @status=Status, @documentdesc=Description, @rcode=0 from PMIL with (nolock) 
    	where PMCo=@pmco and Project=@project and InspectionType=@doctype and InspectionCode=@document
    	
    IF @retcategory = 'SBMTL'
    BEGIN
		SELECT @status = [Status], @documentdesc = [Description], @rcode = 0
		FROM dbo.PMSubmittal
		WHERE PMCo = @pmco AND Project = @project AND DocumentType = @doctype AND SubmittalNumber = @document
    END	
    	
    IF @retcategory = 'SBMTLPCKG'
    BEGIN
		SELECT @status = [Status], @documentdesc = [Description], @rcode = 0
		FROM dbo.PMSubmittalPackage
		WHERE PMCo = @pmco AND Project = @project AND DocType = @doctype AND Package = @document
    END	
    
    if @documentdesc is not null select @msg=@documentdesc
    
    -- get status description from PMSC
    -- Not always necessary to pass in the status.
    if @status is not null
        begin
        select @statusdesc = Description from bPMSC with (nolock) where Status = @status
        if @@rowcount = 0
    	   begin
    	   select @msg = 'PM Status ' + isnull(@status,'') + ' not on file!', @rcode = 1
           goto bspexit
    	   end
        end
    
   bspexit:
    	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspPMDocumentVal] TO [public]
GO
