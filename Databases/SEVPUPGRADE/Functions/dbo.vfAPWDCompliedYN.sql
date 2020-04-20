SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE    function [dbo].[vfAPWDCompliedYN]
  (@apco bCompany, @mth bMonth, @aptrans bTrans, @userid bVPUserName, @apline smallint)
      returns bYN
   /***********************************************************
    * CREATED BY	: MV 02/14/2007
    * MODIFIED BY	: MV 04/24/07 check for vendor compl
    *					DC 02/25/09 - #132186  - Add an APRef field in SL Compliance associated to AP Ref in Accounts payable
    *					GF 06/25/2010 - issue #135813 expanded SL to varchar(30)
    *					GP 8/4/2011 - TK-07144 changed bPO to varchar(30)
    *
    * USAGE:
    * Used to return a Complied flag value of "Y" or "N" to update
	*	bAPWD.CompliedYN 
    *
    * INPUT PARAMETERS
    * 	@apco
    * 	@mth
    * 	@aptrans
    *	@userid 
    *	@apline
    *
    * OUTPUT PARAMETERS
    *  @compliedyn      
    *
    *****************************************************/
      as
      begin
          
        declare @compliedyn bYN,@invdate bDate, @linetype tinyint, 
		 @po varchar(30), @sl VARCHAR(30), @vendorgroup bGroup, @vendor bVendor,
		 @complied bYN, @rc int,
		 @apref bAPReference --DC #132186
 
		--initialize compliedyn flag
		select @compliedyn = 'Y', @rc = 0

		--get linetype info from APTL
 		select @linetype=LineType, @po=PO, @sl=SL 
		from bAPTL where APCo=@apco and APTrans=@aptrans and APLine=@apline and Mth=@mth

		-- get header info from APTH
		select @invdate= InvDate,@vendorgroup=VendorGroup,@vendor=Vendor,
				@apref = APRef  --DC #132186
		 from APTH where APCo=@apco and Mth=@mth and APTrans=@aptrans 

		-- check if vendor is out of compliance
		if exists(select 1 from bAPVC v join bHQCP h on v.CompCode=h.CompCode
   		where v.APCo=@apco and v.VendorGroup=@vendorgroup and v.Vendor=@vendor and h.AllInvoiceYN='Y'
   		and v.Verify='Y' and ((CompType='D' and (ExpDate<@invdate or
   		ExpDate is null)) or (CompType='F' and (Complied='N' or Complied is null))))
		begin
		select @compliedyn='N'
		goto exitfunction
		end
		
	   --if line is PO check PO compliance
	   if @linetype=6
   		begin
   		if exists(select * from bPOCT join bHQCP on bHQCP.CompCode=bPOCT.CompCode
   			where POCo=@apco and PO=@po and bPOCT.Verify='Y' 
   			and ((CompType='D' and (ExpDate<@invdate or ExpDate is null)) or
   				 (CompType='F' and (Complied='N' or Complied is null))))
   			begin
   			select @compliedyn='N'
			goto exitfunction
   			end
   		end
   		
		-- if line is SL check SL compliance	   
	   if @linetype=7
   		begin
   		if exists(select 1 from bSLCT join bHQCP on bHQCP.CompCode=bSLCT.CompCode
   			where SLCo=@apco and SL=@sl and bSLCT.Verify='Y' and 
   				(bSLCT.APRef is null or bSLCT.APRef = @apref) and  --DC #132186
   				((CompType='D' and (ExpDate<@invdate or ExpDate is null)) or (CompType='F' and (Complied='N' or Complied is null))))
   				begin
   				select @compliedyn='N'
				goto exitfunction
   				end
   		end   		  
 
  	exitfunction:
  			
  	return @compliedyn
      end


GO
GRANT EXECUTE ON  [dbo].[vfAPWDCompliedYN] TO [public]
GO
