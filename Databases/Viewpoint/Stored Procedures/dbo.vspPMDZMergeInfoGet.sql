SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***********************************************************************/
CREATE procedure [dbo].[vspPMDZMergeInfoGet]
/************************************************************************
* Created By:	GF 05/18/2007 6.x
* Modified By:	GF 06/25/2010 - issue #135813 expanded SL to varchar(30)
*				GF 03/18/2011 - TK-02607
*				GF 03/29/2011 - TK-03298
*				GF 04/11/2011 - TK-04056
*				GF 05/03/2011 - TK-04388
*
*
* Purpose of Stored Procedure is to get the document merge fields and
* query statements from PMDZ to use to merge data with word template.
* Called from PMDocCreateAndSend form.
*
*
*
* Input parameters:
* PM Company
* Project
* Document Category
* User Name
* VendorGroup
* SentToFirm
* SentToContact
* Document Type if any
* Document
* SL
*
* Output parameters:
* @fields		Merge Field Names
* @mainquery	Main Query String
* @itemquery	Item Query String if any
*
* returns 0 if successfull
* returns 1 and error msg if failed
*
*************************************************************************/
(@pmco bCompany, @project bProject, @doccategory varchar(10), @user bVPUserName,
 @vendorgroup bGroup, @sequence int, @doctype VARCHAR(30), @document VARCHAR(30),
 @sl VARCHAR(30) = null,
 @fields varchar(max) output, @mainquery varchar(max) output,
 @itemquery varchar(max) output, @msg varchar(255) output)
as
set nocount on

declare @rcode int

select @rcode = 0

---- when doc category = 'SUB' then use @sl in where clause
if isnull(@doccategory,'') = 'SUB'
	begin
	select @fields = HeaderString, @mainquery = QueryString, @itemquery = ItemQueryString
	from dbo.PMDZ with (nolock) where PMCo=@pmco and Project=@project and DocCategory=@doccategory
	and UserName=@user and Sequence=@sequence and SL=@sl 
	if @@rowcount = 0
		begin
		select @msg = 'Invalid Subcontract', @rcode = 1
		goto bspexit
		end
	goto bspexit
	end

---- if category is 'ISSUE' there may not be a document type
IF ISNULL(@doccategory,'') = 'ISSUE'
	begin
	select @fields = HeaderString, @mainquery = QueryString, @itemquery = ItemQueryString
	from dbo.PMDZ with (nolock) where PMCo=@pmco and Project=@project and DocCategory=@doccategory
	and UserName=@user and Sequence=@sequence and Document=@document
	if @@rowcount = 0
		begin
		select @msg = 'Invalid document', @rcode = 1
		goto bspexit
		end
	goto bspexit
	END
	
---- when doc category = 'TRANSMIT' or 'SUBCO' then @doctype is not used in where clause
----TK-04056
if isnull(@doccategory,'') IN ('TRANSMIT','SUBCO','COR','PURCHASECO', 'CCO')
	begin
	select @fields = HeaderString, @mainquery = QueryString, @itemquery = ItemQueryString
	from dbo.PMDZ with (nolock) where PMCo=@pmco and Project=@project and DocCategory=@doccategory
	and UserName=@user and Sequence=@sequence and Document=@document
	if @@rowcount = 0
		begin
		select @msg = 'Invalid document', @rcode = 1
		goto bspexit
		end
	goto bspexit
	end
else
	---- assume doctype and document in where clause
	begin
	select @fields = HeaderString, @mainquery = QueryString, @itemquery = ItemQueryString
	from dbo.PMDZ with (nolock) where PMCo=@pmco and Project=@project and DocCategory=@doccategory
	and UserName=@user and Sequence=@sequence and DocType=@doctype and Document=@document
	if @@rowcount = 0
		begin
		select @msg = 'Invalid Document', @rcode = 1
		goto bspexit
		end
	end



bspexit:
	if @rcode <> 0 select @msg = isnull(@msg,'')
	return @rcode

GO
GRANT EXECUTE ON  [dbo].[vspPMDZMergeInfoGet] TO [public]
GO
