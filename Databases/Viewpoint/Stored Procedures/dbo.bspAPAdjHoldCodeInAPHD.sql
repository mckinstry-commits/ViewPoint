SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  Stored Procedure dbo.bspAPAdjHoldCodeInAPHD    Script Date: 8/28/99 9:33:55 AM ******/
   CREATE  procedure [dbo].[bspAPAdjHoldCodeInAPHD]
   
      
   /***********************************************************
    * CREATED BY: EN 07/08/97
    * MODIFIED By : EN 4/3/98
    * 			MV 10/18/02 - quoted identifiers
    *			MV 03/25/05 - #27262 - validate vendor hold code if mode=A
	*			MV 03/05/09 - #132482 - validate hold code if mode=A
				AR 11/29/10 - #142278 - removing old style joins replace with ANSI correct form
    * USAGE:
    * Add or delete hold codes to all open AP transactions
    * for specified vendors.  An error is returned if anything goes
    * wrong.             
    * 
    * Note: A trigger has been set up for APHD to update payment
    * status flag in APTD depending on how APHD is modified.
    *
    *  INPUT PARAMETERS
    *   @apco	AP company number
   
    *   @vendorgrp	vendor group
    *   @vendr	vendor number  
    *   @holdcode	Hold code to be added or deleted
    *   @mode	'A' for adds, 'D' for deletes
    *
    * OUTPUT PARAMETERS
    *   @msg      error message if error occurs 
    *
    * RETURN VALUE
    *   0   success
    *   1   fail
   *******************************************************************/ 
   (@apco bCompany, @vendorgrp bGroup, @vendr bVendor, @holdcode bHoldCode, 
   	@mode char(1), @msg varchar(90) output)
   as
   set nocount on
   
   declare @rcode int, @seq tinyint, @mth bMonth,
   	@aptrans bTrans, @apline smallint, @apseq tinyint,
   	@paidmth bMonth, @cmref bCMRef, @APDtlopened tinyint
   
   select @rcode=0
   
   /* set open cursor flag to false */
   select @APDtlopened = 0
  
  
   if @mode='A'
   	begin
	 /* validate Hold Code */
	   if not exists (select * from HQHC where HoldCode=@holdcode)
   		begin
       		select @msg = 'Invalid Hold Code!', @rcode = 1
       		goto bspexit
      		end
	 /* validate Vendor Hold Code */
   	  if not exists (select * from APVH where APCo=@apco and VendorGroup=@vendorgrp 
   	  		and Vendor=@vendr and HoldCode=@holdcode)
   	  	begin
   	      	select @msg = 'Invalid Vendor Hold Code!', @rcode = 1
   	      	goto bspexit
   	     	end
   	end
   
   /* spin through details */
	DECLARE bcAPDetail CURSOR
   	FOR 
   	--142278
   		SELECT DISTINCT h.Mth, 
   						h.APTrans, 
   						d.APLine, 
   						d.APSeq
   
   		FROM dbo.bAPTH h
   			JOIN dbo.bAPTD d ON	h.APCo = d.APCo  
   								AND	h.Mth = d.Mth	 
   								AND h.APTrans = d.APTrans 
   		WHERE h.APCo = @apco 
   			AND h.VendorGroup = @vendorgrp 
   			AND h.Vendor = @vendr
   			AND h.InUseBatchId IS NULL 
   			AND h.PrePaidChk IS NULL
   			AND d.[Status] NOT IN (3,4)
   			
   
   /* open cursor */
   open bcAPDetail
   
   /* set open cursor flag to true */
   select @APDtlopened = 1
   
   /* loop through details */
   dtl_search_loop:
   	fetch next from bcAPDetail into @mth, @aptrans, @apline, @apseq
   
   	if @@fetch_status <> 0 goto bspexit
   
   	/* add hold code to APHD for trans/line/seq */
   
   	if @mode='A'
   		begin
   		if not exists (select * from bAPHD where APCo=@apco and Mth=@mth
   				and APTrans=@aptrans and APLine=@apline and APSeq=@apseq
   
   				and HoldCode=@holdcode)
   			begin
   			insert bAPHD (APCo, Mth, APTrans, APLine, APSeq, HoldCode)
   				values(@apco, @mth, @aptrans, @apline, @apseq, @holdcode)
   			if @@rowcount=0
   				begin
   				select @msg = 'Could not insert hold code.  Update cancelled!'
   				goto bspexit
   
   				end
   			end
   		end
   
   	/* delete hold code from APHD for trans/line/seq */
   	if @mode='D'
   		begin
   		if exists (select * from bAPHD where APCo=@apco and Mth=@mth
   				and APTrans=@aptrans and APLine=@apline and APSeq=@apseq
   				and HoldCode=@holdcode)
   			begin
   			delete from bAPHD
   				where APCo=@apco and Mth=@mth and APTrans=@aptrans
   				and APLine=@apline and APSeq=@apseq and HoldCode=@holdcode
   			if @@rowcount=0
   
   				begin
   				select @msg = 'Could not delete hold code.  Update cancelled!'
   				goto bspexit
   				end
   			end
   		end
   		
   	goto dtl_search_loop
   	
   
   bspexit:
   	if @APDtlopened = 1
   		begin
   		close bcAPDetail
   		deallocate bcAPDetail
   		end	
 
   
   
   	return @rcode

GO
GRANT EXECUTE ON  [dbo].[bspAPAdjHoldCodeInAPHD] TO [public]
GO
