SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
 /**************************************************    
  * Created By: Saurabh N 11/06/2012     
  *    
  * USAGE:  Used to validate groups related to company.
  * 
  * Used by frmCompanySelect of Company Copy Wizard
  *    
  *************************************************/    
CREATE PROCEDURE [dbo].[vspVACompanyVal]  
 (  
 @vaco bCompany,   
 @custout bGroup = null out,   
 @vendorout bGroup = null out,   
 @matlout bGroup = null out,  
 @taxout bGroup = null out,   
 @phaseout bGroup = null out,    
 @emout bGroup = null out,   
 @shopout bGroup = null out,     
 @contactout bGroup = null out    
 )  
AS  
BEGIN  
 -- SET NOCOUNT ON added to prevent extra result sets from  
 -- interfering with SELECT statements.  
 SET NOCOUNT ON;  
select @vendorout = VendorGroup, @matlout = MatlGroup, @phaseout = PhaseGroup, @custout = CustGroup,   
 @taxout = TaxGroup, @emout = EMGroup, @shopout = ShopGroup,@contactout = ContactGroup from bHQCO where HQCo = @vaco  
       
END  
GO
GRANT EXECUTE ON  [dbo].[vspVACompanyVal] TO [public]
GO
