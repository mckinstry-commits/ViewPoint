SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  proc [dbo].[vspSLUpdateAPLoadProc]
/********************************************************
* CREATED BY: 	DC 12/21/06
* MODIFIED BY:	DC 12/6/07 - 126424 - Getting invalid GL Company error when opening batch
*		TJL 04/24/09 - Issue #129889, International Claims and Certifications.
*				GF 10/01/2012 TK-18283 added output for vendor group
*				GF 10/18/2012 TK-18032 removed use certified flag
*             
* USAGE:
* 	Retrieves common info from AP Company for use in SLUpdateAP
*	form's DDFH LoadProc field 
*
* INPUT PARAMETERS:
*	@co			AP Co#
*
* OUTPUT PARAMETERS:
*	@paycategoryyn		Pay Categories option
*	@overridepaytype		Override Pay Type

* RETURN VALUE:
* 	0 	    Success
*	1 & message Failure
*
**********************************************************/
(@co bCompany=0, @paycategoryyn bYN = null output,@overridepaytype bYN = null output,
 @paycategory int = null output, @subpaytype tinyint = null output, @glco bCompany =null output,
 ----TK-18283
 @VendorGroup bGroup OUTPUT,
 @errmsg varchar(255) output)

as 
set nocount on
declare @rcode int, @apcopaycategory int
select @rcode = 0

	--Validate the SL Company+
	IF not exists(select top 1 1 from SLCO with (nolock) where SLCo = @co)
		BEGIN
		select @errmsg = 'Invalid SL Company.', @rcode = 1
		goto vspexit
		end

	--check bAPCO first
	----TK-18283
	select @subpaytype=a.SubPayType, 
			@paycategoryyn=a.PayCategoryYN,
			@overridepaytype=a.OverridePayType,
			@glco=a.GLCo,
    		@apcopaycategory=a.PayCategory,
			----TK-18283
			@VendorGroup = c.VendorGroup
	from bAPCO a WITH (NOLOCK) 
	join bSLCO s with (nolock) on s.SLCo = a.APCo
	JOIN bHQCO c WITH (NOLOCK) ON c.HQCo = a.APCo
	where a.APCo = @co
    		if @@rowcount=0
    		begin
    			select @rcode = 1
    			goto vspexit
    		end

    -- get paytypes and glaccts from bAPPC if using pay category
    if @paycategoryyn='Y'
    	begin
    		--User Profile default Pay Category
    		select @paycategory = PayCategory 
    		from vDDUP WITH (NOLOCK)
    		where rtrim(ltrim(VPUserName))=rtrim(ltrim(user_name()))
    		if isnull(@paycategory,0)> 0
				begin
					select @subpaytype=SubPayType 
					from bAPPC WITH (NOLOCK)
					where APCo=@co and PayCategory=@paycategory 
					if @@rowcount = 0
						begin
							select @rcode = 1  
							goto vspexit
						end
				end
   			else
   				begin
   					select @paycategory = null --if DDUP returns 0 paycategory clear it
   				end
    		
    		--Pay Category default in bAPCO 
    		if isnull(@apcopaycategory,0)> 0
    			begin
    				select @subpaytype=SubPayType 
    				from bAPPC WITH (NOLOCK)
    				where APCo=@co and PayCategory=@apcopaycategory 
    				if @@rowcount = 0
    					begin
    						select @rcode = 1  
    						goto vspexit
    					end
    				else
    					select @paycategory=@apcopaycategory
    			end
		end
   	else
   		begin
   			select @paycategory = null --if APCO returns 0 paycategory clear it
   		end
    

vspexit:

return @rcode



GO
GRANT EXECUTE ON  [dbo].[vspSLUpdateAPLoadProc] TO [public]
GO
