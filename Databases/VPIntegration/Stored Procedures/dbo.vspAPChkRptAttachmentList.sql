SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE            PROC [dbo].[vspAPChkRptAttachmentList]
    /************************************
    * Created: MV 03/02/09 - #129891 email vendor pay info as attachment
    * Modified:	MV 11/25/09 - #136452 - return APPB UniqueAttchID
				AR 10/27/10 - #135214 Cleaning up code to pass SQL Upgrade Advisor
     
	*
    * This SP is called from form APChkPrnt to return a list of BatchSeq with vendor info
    *
    ***********************************/
(
  @apco bCompany,
  @month bMonth,
  @batchid bBatchID,
  @cmco bCompany,
  @cmacct bCMAcct
)
AS 
SET NOCOUNT ON
-- #135214 removing the alaising of a column that has the same name of the alias
SELECT  a.BatchSeq,
        a.CMRef,
        v.Name,
        v.EMail AS Email,
        a.KeyID,
        a.UniqueAttchID
FROM    dbo.bAPPB a WITH ( NOLOCK )
        JOIN dbo.bAPVM v WITH ( NOLOCK ) ON v.VendorGroup = a.VendorGroup
                                        AND v.Vendor = a.Vendor
WHERE   a.Co = @apco
        AND a.Mth = @month
        AND a.BatchId = @batchid
        AND a.PayMethod = 'C'
        AND a.CMCo = @cmco
        AND a.CMAcct = @cmacct
ORDER BY a.BatchSeq

RETURN 





GO
GRANT EXECUTE ON  [dbo].[vspAPChkRptAttachmentList] TO [public]
GO
