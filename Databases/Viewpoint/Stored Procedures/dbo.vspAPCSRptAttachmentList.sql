SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE            PROC [dbo].[vspAPCSRptAttachmentList]
    /************************************
    * Created: MV 05/03/12 - TK-146541 email credit service vendor remittance info as attachment
    * Modified:	
	*
    * This SP is called from form APCreditServiceExportFileGen to return a list
    * of BatchSeq with vendor info for all credit service payments in the batch
    *
    ***********************************/
(
  @APCo bCompany,
  @Month bMonth,
  @BatchId bBatchID,
  @CMCo bCompany,
  @CMAcct bCMAcct
)
AS 
SET NOCOUNT ON
SELECT  a.BatchSeq,
        a.CMRef,
        v.Name,
        v.EMail AS Email,
        a.KeyID,
        a.UniqueAttchID
FROM    dbo.bAPPB a WITH ( NOLOCK )
        JOIN dbo.bAPVM v WITH ( NOLOCK ) ON v.VendorGroup = a.VendorGroup
                                        AND v.Vendor = a.Vendor
WHERE   a.Co = @APCo
        AND a.Mth = @Month
        AND a.BatchId = @BatchId
        AND a.PayMethod = 'S'
        AND a.CMCo = @CMCo
        AND a.CMAcct = @CMAcct
ORDER BY a.BatchSeq

RETURN 






GO
GRANT EXECUTE ON  [dbo].[vspAPCSRptAttachmentList] TO [public]
GO
