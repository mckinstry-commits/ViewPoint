SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE         PROCEDURE [dbo].[brptAPWorkFile]
 	(@Co bCompany=1, 
 @UserID bVPUserName = '',
 @BegMth bMonth='01/01/1950',
 @EndMth bMonth='12/1/2050', 
 @BegVendor bVendor=1, 
 @EndVendor bVendor=999999 )   
     
     /* created 08/14/00 HongSoo				*/
	 /*	Mod 6/6/2002 DarinH - Issue 17571		*/
     
     /* used in APPayWorkFile.rpt				*/
     
     /*  declare @Co bCompany, @PayMth bMonth, @ChkVendorBal bYN, @BegVendorName varchar(10),					 */
	 /*	@EndVendorName varchar(10),																				 */
	 /*	@PaymentMethod char(1), @BatchId bBatchID																 */
     /* select  @Co=1, @PayMth='08/01/2000', @ChkVendorBal='Y', @BegVendorName=' ', @EndVendorName='zzzzzzzzzz', */
     /* @PaymentMethod='C', @BatchId=105																		 */ 
     
     /* Removed cursors for SL and PO then, added a section for AP Invoices when AllInvoicesYN is Y				 */
     /* NF 10/22/03 */
     /* Added compliance description - issue 23430, Added restriction for AllInvoicesYN for Vend Compliance		 */
     
     /* - issue 23454  DH 1/13/04																				 */ 
     /* issue 120302 CR 5/23/06  copied brptCheckPrev															 */
     
     /* Modified: 09/20/2011					*/ 
     /* Modified by: Dan K						*/
	 /* Issue: B06495							*/
	 /* Reason: SM Has been added to the first data set as compliance validation is not required at this time	 */
     
     as
     

 
     /*create table #comp(APMth datetime not null,
              APTrans int not null,
              SLCompliance varchar(255) null,
     	      POCompliance varchar(255) null,
              APCompliance varchar(255) null,
              SLCompDesc varchar(60) null,
 	          POCompDesc varchar(60) null,
              APCompDesc varchar(60) null)  */
     
   /* declare bcSLCompliance cursor for       NF 10/22/03 */
   /*Check the compliance and insert records into temp table NF 10/22/03*/
 --Insert into #comp
 
 
    SELECT
 	APWH.APCo, 
 	APWH.Mth, 
 	APWH.APTrans, 
 	APWH.UserId, 
 	CompSort=0, 
 	APWH.PayMethod, 
 	APTH.Vendor, 
 	APTH.APRef,
 	APVM.SortName, 
 	APVendorName=APVM.Name, 
 	APTH.Description, 
 	APTH.InvDate, 
 	APWH.DueDate, 
 	APWH.DiscDate, 
 	APWHPayYN=APWH.PayYN, 
 	APWH.PayControl, 
 	APWH.CMCo, 
 	APWH.CMAcct, 
    APWHHold=APWH.HoldYN,
 	APTL.LineType, 
 	APTL.PO, 
 	APTL.POItem, 
 	APTL.SL, 
 	APTL.SLItem, 
 	APTL.JCCo, 
 	APTL.Job, 
 	APTL.EMCo, 
 	APTL.WO, 
 	APTL.WOItem, 
 	APTL.Equip, 
    APTL.INCo, 
    APTL.Loc, 
    APTL.GLCo, 
    APTL.GLAcct, 
    APTLDesc=APTL.Description, 
    APWD.APLine, 
    APWD.APSeq, 
    APWDHold=APWD.HoldYN, 
    APWDPayYN=APWD.PayYN, 
    APWD.DiscTaken, 
    APWD.Amount,
    HQCO.HQCo, 
    HQName=HQCO.Name,
    SLCompliance=null, 
    POCompliance=null, 
    APCompliance=null, 
    SLCompDesc=null, 
    POCompDesc=null, 
    APCompDesc=null,
    APTL.SMCo,
    APTL.SMWorkOrder,
    APTL.Scope
 	
    
 FROM APWH 
    Join APTH with (nolock) on APWH.APCo = APTH.APCo and APWH.Mth =  APTH.Mth and APWH.APTrans = APTH.APTrans 
    Join APTL with (nolock) on APTH.APCo=APTL.APCo and APTH.Mth = APTL.Mth and APTH.APTrans = APTL.APTrans
    Join APWD with (nolock) on APTL.APCo = APWD.APCo and APTL.Mth = APWD.Mth and APTL.APTrans = APWD.APTrans and APTL.APLine = APWD.APLine
	JOIN HQCO HQCO with (nolock) ON  APTH.APCo=HQCO.HQCo
 	JOIN APVM with (nolock) ON  APTH.VendorGroup=APVM.VendorGroup AND  APTH.Vendor=APVM.Vendor
	
     WHERE APWH.APCo=@Co AND APWH.Mth >= @BegMth AND APWH.Mth <= @EndMth AND APVM.Vendor >= @BegVendor AND APVM.Vendor <=@EndVendor  
           AND (case when @UserID<>'' then @UserID else 'Z' end) = (case when @UserID <> '' then APWH.UserId else 'Z' end)
          
union all

SELECT distinct 
 	APWH.APCo, 
 	APWH.Mth, 
 	APWH.APTrans, 
 	APWH.UserId, 
 	CompSort=1, 
 	null, 
 	APTH.Vendor, 
 	APTH.APRef, 
 	APVM.SortName, 
 	null, 
 	null, 
 	null, 
 	null, 
 	null, 
 	APWHPayYN=APWH.PayYN, 
 	null, 
 	null, 
 	null, 
 	null, 
    null, 
    null, 
    null, 
    APTL.SL, 
    null, 
    null, 
    null, 
    null, 
    null, 
    null, 
    null, 
    null, 
    null, 
    null, 
    null, 
    null, 
    null, 
    null, 
    null, 
    /*APWDPayYN=APWD.PayYN*/'Y', 
    null, 
    null,
    null, 
    null,
    SLCompliance=SLCT.CompCode, 
    POCompliance=null, 
    APCompliance=null, 
    SLCompDesc=HQCP.Description, 
    POCompDesc=null, 
    APCompDesc=null,
    NULL,
    NULL,
    NULL


 FROM APWH
    Join APTH with (nolock) on APWH.APCo = APTH.APCo and APWH.Mth =  APTH.Mth and APWH.APTrans = APTH.APTrans 
    JOIN APTL with (nolock) ON APTH.APCo=APTL.APCo AND APTH.Mth=APTL.Mth AND APTH.APTrans=APTL.APTrans
    --Join APWD with (nolock) on APWH.APCo = APWD.APCo and APWH.Mth = APWD.Mth and APWH.APTrans = APWD.APTrans 
    JOIN SLCT with (nolock) ON APTL.APCo=SLCT.SLCo AND APTL.SL=SLCT.SL
    left Join HQCP with (nolock) on SLCT.CompCode=HQCP.CompCode --AND HQCP.AllInvoiceYN='Y'
    JOIN APVM with (nolock) ON  APTH.VendorGroup=APVM.VendorGroup AND  APTH.Vendor=APVM.Vendor
     
    
 WHERE APTH.APCo=@Co AND APTH.Mth>=@BegMth and APTH.Mth<=@EndMth 
       AND  (SLCT.Verify='Y' and (SLCT.Complied <>'Y' or SLCT.Complied is null) 
       and (SLCT.ExpDate<APTH.InvDate or SLCT.ExpDate IS NULL) 
       OR (SLCT.Verify='Y' and SLCT.ExpDate is null and SLCT.Complied='N') )

union all

SELECT distinct
 	APWH.APCo, 
 	APWH.Mth, 
 	APWH.APTrans, 
 	APWH.UserId, 
 	CompSort=1, 
 	null, 
 	APTH.Vendor, 
 	APTH.APRef,
 	APVM.SortName, 
 	null, 
 	null, 
 	null, 
 	null, 
 	null, 
 	APWHPayYN=APWH.PayYN, 
 	null, 
 	null, 
 	null, 
 	null, 
 	null, 
 	APTL.PO, 
 	null, 
 	null, 
 	null, 
 	null, 
 	null, 
 	null, 
 	null, 
 	null, 
 	null, 
    null, 
    null, 
    null, 
    null, 
    null, 
    null, 
    null, 
    null, 
    /*APWDPayYN=APWD.PayYN*/'Y', 
    null, 
    null,
    null, 
    null,
    SLCompliance=null, 
    POCompliance=POCT.CompCode, 
    APCompliance=null, 
    SLCompDesc=null, 
    POCompDesc=HQCP.Description, 
    APCompDesc=null,
    NULL,
    NULL,
    NULL

  	FROM APWH
    Join APTH with (nolock) on APWH.APCo = APTH.APCo and APWH.Mth = APTH.Mth and APWH.APTrans = APTH.APTrans 
    join APTL with (nolock) on APTH.APCo = APTL.APCo and APTH.Mth = APTL.Mth and APTH.APTrans = APTL.APTrans
    --Join APWD with (nolock) on APWH.APCo = APWD.APCo and APWH.Mth = APWD.Mth and APWH.APTrans = APWD.APTrans 
    JOIN POCT with (nolock) ON APTL.APCo=POCT.POCo AND APTL.PO=POCT.PO 
    left JOIN HQCP with (nolock) ON HQCP.CompCode=POCT.CompCode --AND HQCP.AllInvoiceYN='Y'
    JOIN APVM with (nolock) ON  APTH.VendorGroup=APVM.VendorGroup AND  APTH.Vendor=APVM.Vendor

    WHERE APTH.APCo=@Co AND APTH.Mth>=@BegMth and APTH.Mth<=@EndMth 
      	  AND (POCT.Verify='Y' and (POCT.Complied <>'Y' or POCT.Complied is null)
          and (POCT.ExpDate<APTH.InvDate or POCT.ExpDate IS NULL)
          OR (POCT.Verify='Y' and POCT.ExpDate is null and POCT.Complied='N') )
union all

SELECT distinct
 	APWH.APCo, 
 	APWH.Mth, 
 	APWH.APTrans, 
 	APWH.UserId, 
 	CompSort=1, 
 	null, 
 	APTH.Vendor, 
 	APTH.APRef,
 	APVM.SortName, 
 	APVendorName=APVM.Name, 
 	null, 
 	null, 
 	null, 
 	null, 
 	APWHPayYN=APWH.PayYN, 
 	null, 
 	null, 
 	null, 
 	null, 
 	null, 
 	null, 
 	null, 
 	null, 
 	null, 
 	null, 
 	null, 
 	null, 
 	null, 
 	null, 
 	null,
    null, 
    null, 
    null, 
    null, 
    null,
    null, 
    null, 
    null, 
    APWDPayYN=APWD.PayYN, 
    null, 
    null,
    null, 
    null,
    SLCompliance=null, 
    POCompliance=null, 
    APCompliance=APVC.CompCode, 
    SLCompDesc=null, 
    POCompDesc=null, 
    APCompDesc=HQCP.Description,
    NULL,
    NULL,
    NULL

    FROM APWH
        
    Join APTH with (nolock) on APWH.APCo = APTH.APCo and APWH.Mth =  APTH.Mth and APWH.APTrans = APTH.APTrans 
    Join APWD with (nolock) on APWH.APCo = APWD.APCo and APWH.Mth = APWD.Mth and APWH.APTrans = APWD.APTrans 
    JOIN APVC with (nolock) ON APTH.APCo=APVC.APCo AND APTH.Vendor=APVC.Vendor
    JOIN APVM with (nolock) ON APTH.VendorGroup=APVM.VendorGroup AND  APTH.Vendor=APVM.Vendor
    JOIN HQCP with (nolock) ON HQCP.CompCode=APVC.CompCode AND HQCP.AllInvoiceYN='Y'
    
                      
  	WHERE APTH.APCo=@Co AND APTH.Mth>=@BegMth  and APTH.Mth <= @EndMth 
      	      AND  (APVC.Verify='Y' and (APVC.Complied <>'Y' or APVC.Complied is null)
        	  and (APVC.ExpDate<APTH.InvDate or APVC.ExpDate IS NULL)
              or (APVC.Verify='Y' and APVC.ExpDate is null and APVC.Complied='N') )

GO
GRANT EXECUTE ON  [dbo].[brptAPWorkFile] TO [public]
GO
