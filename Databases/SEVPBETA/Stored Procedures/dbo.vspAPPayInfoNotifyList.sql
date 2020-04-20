SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE           proc [dbo].[vspAPPayInfoNotifyList]
    /************************************
    * Created: MV 03/03/09 - #129891 email vendor pay info as attachment
    * Modified:MV 05/13/09 - #129891 - don't include voided payments
	*			MV 11/25/09 - #136452 - return UniqueAttchID and KeyID - HQAT table not needed 
	*
    * This SP is called from form APEmailPayInfo to return a list of vendors to email
    *
    ***********************************/
    (@apco bCompany, @cmco bCompany, @cmacct bCMAcct, @paiddate bDate = null, @paidmth bMonth = null, @batchid int = null,
		@vendorgroup bGroup = null, @vendor bVendor = null )
  
   as
   set nocount on

if @paiddate = '' select @paiddate = null
if @paidmth = '' select @paidmth = null


select v.EMail 'EMail' , p.UniqueAttchID 'UniqueAttachID', v.PayInfoDelivMthd 'DeliveryMethod', p.KeyID 'KeyID'
	from dbo.APPH (nolock) p 
	join dbo.APVM (nolock) v on p.VendorGroup=v.VendorGroup and p.Vendor=v.Vendor
	join dbo.APCO (nolock) c on p.APCo=c.APCo
	where p.APCo=@apco and p.CMCo=@cmco and p.CMAcct=@cmacct and p.PaidDate = isnull(@paiddate,p.PaidDate)
		and p.PaidMth=isnull(@paidmth,p.PaidMth) and p.BatchId=isnull(@batchid,p.BatchId) 
		and p.VendorGroup= isnull(@vendorgroup,p.VendorGroup) and p.Vendor=isnull(@vendor,p.Vendor)
		and p.VoidYN = 'N'
		and v.PayInfoDelivMthd in ('A','E')

			

--Original select statement
--select v.EMail 'EMail' ,h.AttachmentID 'AttachmentID', v.PayInfoDelivMthd 'DeliveryMethod'
--	from dbo.HQAT (nolock) h
--	left join dbo.APPH (nolock) p on h.HQCo=p.APCo and h.UniqueAttchID=p.UniqueAttchID
--	join dbo.APVM (nolock) v on p.VendorGroup=v.VendorGroup and p.Vendor=v.Vendor
--	join dbo.APCO (nolock) c on p.APCo=c.APCo
--	where h.FormName='APPayEdit' and h.HQCo=@apco and p.CMCo=@cmco and p.CMAcct=@cmacct and p.PaidDate = isnull(@paiddate,p.PaidDate)
--		and p.PaidMth=isnull(@paidmth,p.PaidMth) and p.BatchId=isnull(@batchid,p.BatchId) 
--		and p.VendorGroup= isnull(@vendorgroup,p.VendorGroup) and p.Vendor=isnull(@vendor,p.Vendor)
--		and p.VoidYN = 'N'
--		and v.PayInfoDelivMthd <> 'N'
--		and h.AttachmentTypeID=c.VendorPayAttachTypeID
--		and h.AttachmentID= (select max (h2.AttachmentID)
--			from dbo.HQAT (nolock) h2
--			left join dbo.APPH (nolock) p2 on h2.HQCo=p2.APCo and h2.UniqueAttchID=p2.UniqueAttchID
--			where p2.APCo=p.APCo and p2.CMCo=p.CMCo and p2.CMAcct=p.CMAcct and p2.PaidDate = p.PaidDate
--				and p2.PaidMth=p.PaidMth and p2.BatchId=p.BatchId and p2.UniqueAttchID=p.UniqueAttchID 
--				and p2.VendorGroup= p.VendorGroup and p2.Vendor=p.Vendor)
	return 

          

GO
GRANT EXECUTE ON  [dbo].[vspAPPayInfoNotifyList] TO [public]
GO
