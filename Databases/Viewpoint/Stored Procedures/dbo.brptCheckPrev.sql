SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE          PROCEDURE [dbo].[brptCheckPrev]
 	(@Co bCompany=1, 
 @PayMth bMonth='03/01/03', 
 @ChkVendorBal bYN='Y', 
 @BegVendorName bVendor=1, 
 @EndVendorName bVendor=999999,
 @BatchId bBatchID=145)   
     
     /*created 08/14/00 HongSoo       Mod 6/6/2002 DarinH - Issue 17571*/
     /* used in APPaymentWithCompl.rpt */
      /*  declare @Co bCompany, @PayMth bMonth, @ChkVendorBal bYN, @BegVendorName varchar(10), @EndVendorName varchar(10),
      @PaymentMethod char(1), @BatchId bBatchID 
     
     select  @Co=1, @PayMth='08/01/2000', @ChkVendorBal='Y', @BegVendorName=' ', @EndVendorName='zzzzzzzzzz',
      @PaymentMethod='C', @BatchId=105 */ 
 /*Removed cursors for SL and PO then, added a section for AP Invoices when AllInvoicesYN is Y     NF 10/22/03 */
 /*Added compliance description - issue 23430, Added restriction for AllInvoicesYN for Vend Compliance*/
 /* - issue 23454  DH 1/13/04*/
 
     
     as
     
     set nocount on
     
     declare	@BatchSeq int, 
 @PrevBatchSeq int, 
 @PrevTrans int, 
 @APTrans int ,
 @CompCode varchar(10), 
 @Description varchar(30), 
 @openSLCompliance int, 
 @j varchar(2000), 
 @fetch_status int
 
     create table #comp(BatchSeq int not null,
              APTrans int not null,
              SLCompliance varchar(255) null,
     	     POCompliance varchar(255) null,
              APCompliance varchar(255) null,
              SLCompDesc varchar(60) null,
 	     POCompDesc varchar(60) null,
              APCompDesc varchar(60) null)
     
   /* declare bcSLCompliance cursor for       NF 10/22/03 */
 /*Check the compliance and insert records into temp table NF 10/22/03*/
 Insert into #comp
 
 SELECT distinct APTB.BatchSeq, 
 APTB.APTrans, 
 SLCT.CompCode, NULL, NULL, SLCT.Description, Null, Null
 
 FROM APTB APTB
     JOIN APTL with (nolock) ON  
 	APTB.Co=APTL.APCo AND  
 	APTB.ExpMth=APTL.Mth AND  
 	APTB.APTrans=APTL.APTrans
     JOIN APTH with (nolock) ON  
 	APTB.Co=APTH.APCo AND  
 	APTB.ExpMth=APTH.Mth AND  
 	APTB.APTrans=APTH.APTrans
     JOIN SLCT with (nolock) ON   
 	APTL.APCo=SLCT.SLCo AND  
 	APTL.SL=SLCT.SL
     
 WHERE APTB.Co=@Co   
       AND APTB.Mth=@PayMth
       AND  APTB.BatchId=@BatchId 
       AND  (SLCT.Verify='Y'  
        and (SLCT.Complied <>'Y' 
           or SLCT.Complied is null) 
        and (SLCT.ExpDate<APTH.InvDate 
           or SLCT.ExpDate IS NULL)
                      OR (SLCT.Verify='Y' 
                     and SLCT.ExpDate is null 
                     and SLCT.Complied='N') )
 
 UNION ALL
     
     /*open bcSLCompliance
     
     select @openSLCompliance = 1
     select @j='', 
               @PrevBatchSeq=0, 
               @PrevTrans=0
     while 1=1
        begin
 fetch next from bcSLCompliance into @BatchSeq, @APTrans, @CompCode, @Description
     		select @fetch_status=@@fetch_status
     
         	if @PrevBatchSeq>0 and (@BatchSeq<>@PrevBatchSeq or @PrevTrans<>@APTrans or @fetch_status<>0)
            	begin
     
     		update #comp set SLCompliance=@j 
     		where BatchSeq=@PrevBatchSeq and APTrans=@PrevTrans
     		if @@rowcount=0
    			begin
     				insert into #comp(BatchSeq,APTrans,SLCompliance)
                     			select @PrevBatchSeq,@PrevTrans,@j
         		end
     
            		select @j=''
            	end
     
         	if @fetch_status <> 0 break
     
         	if @j>'' select @j=@j+', '
         	select @j=@j+RTrim(@CompCode)+'  '+RTrim(@Description)
        	if (select datalength(@j))>1980 break
         	select @PrevBatchSeq=@BatchSeq ,@PrevTrans=@APTrans
      end
      	if @openSLCompliance = 1
             begin  close bcSLCompliance  deallocate bcSLCompliance   end    NF 10/22/03 */
      
     /*   declare @openPOCompliance int       NF 10/22/03 */
     /*@BatchSeq int, @PrevBatchSeq int, @PrevTrans int, @APTrans int ,
      @CompCode varchar(10), @Description varchar(30),  @j varchar(2000), @fetch_status int*/
     
     /* declare bcPOCompliance cursor for    NF 10/22/03 */
 
     	SELECT distinct APTB.BatchSeq, APTB.APTrans, NULL,
                         POCT.CompCode, NULL, NULL, POCT.Description, NULL
     	FROM
       	APTB APTB
       	  JOIN APTL with (nolock) ON  
 		APTB.Co=APTL.APCo AND  
 		APTB.ExpMth=APTL.Mth AND  
 		APTB.APTrans=APTL.APTrans
       	  JOIN APTH with (nolock) ON  
 		APTB.Co=APTH.APCo AND  
 		APTB.ExpMth=APTH.Mth AND  
 		APTB.APTrans=APTH.APTrans
       	 JOIN POCT with (nolock) ON  
 		APTL.APCo=POCT.POCo AND  
 		APTL.PO=POCT.PO
 
     	WHERE APTB.Co=@Co   
       		AND APTB.Mth=@PayMth 
      	      	AND  APTB.BatchId=@BatchId 
       		AND  (POCT.Verify='Y' 
                 and (POCT.Complied <>'Y' or POCT.Complied is null)
        	     	and (POCT.ExpDate<APTH.InvDate or POCT.ExpDate IS NULL)
                 OR (POCT.Verify='Y' and POCT.ExpDate is null and POCT.Complied='N') )
         
     /*  open bcPOCompliance
     
     select @openPOCompliance = 1
     select @j='', @PrevBatchSeq=0, @PrevTrans=0
     while 1=1
     begin
         fetch next from bcPOCompliance into @BatchSeq, @APTrans, @CompCode, @Description
     	select @fetch_status=@@fetch_status
     
         if @PrevBatchSeq>0 and (@BatchSeq<>@PrevBatchSeq or @PrevTrans<>@APTrans or @fetch_status<>0)
 begin
     
     		update #comp set POCompliance=@j 
     		where BatchSeq=@PrevBatchSeq and APTrans=@PrevTrans
     		if @@rowcount=0
     			begin
     				insert into #comp(BatchSeq,APTrans,POCompliance)
                     			select @PrevBatchSeq,@PrevTrans,@j
         			end
     
 select @j=''
 end
     
         if @fetch_status <> 0 break
     
         if @j>'' select @j=@j+', '
         select @j=@j+RTrim(@CompCode)+'  '+RTrim(@Description)
         if (select datalength(@j))>1980 break
         select @PrevBatchSeq=@BatchSeq ,@PrevTrans=@APTrans
     end
      if @openPOCompliance = 1
             begin  close bcPOCompliance  deallocate bcPOCompliance   end   NF 10/22/03 */
 
 UNION ALL
 
 select distinct APTB.BatchSeq, APTB.APTrans, NULL, NULL, APVC.CompCode, NULL, NULL, HQCP.Description
          FROM
             APTB APTB
       		JOIN APTH with (nolock) ON  
 			APTB.Co=APTH.APCo AND  
 			APTB.ExpMth=APTH.Mth AND  
 			APTB.APTrans=APTH.APTrans
 
       		JOIN APVC with (nolock) ON  
 			APTH.APCo=APVC.APCo AND  
 			APTH.Vendor=APVC.Vendor
                 JOIN HQCP with (nolock) ON
                         HQCP.CompCode=APVC.CompCode AND
                         HQCP.AllInvoiceYN='Y'
                      
 
 	WHERE APTB.Co=@Co   
       	      AND APTB.Mth=@PayMth 
      	      AND  APTB.BatchId=@BatchId 
       	      AND  (APVC.Verify='Y' 
               and (APVC.Complied <>'Y' or APVC.Complied is null)
        	      and (APVC.ExpDate<APTH.InvDate or APVC.ExpDate IS NULL)
                                 OR (APVC.Verify='Y' and APVC.ExpDate is null and APVC.Complied='N') )
 
 
 
      SELECT
 	APPB.Co, APPB.Mth, APPB.BatchId, APPB.BatchSeq, APPB.PayMethod, APPB.ChkType, APPB.Vendor,
 	APPB.Supplier, APPB.VoidYN,  APVM.SortName, APVendorName=APPB.Name,
 	APTBCo=APTB.Co, APTBMth=APTB.Mth, APTBBatchID=APTB.BatchId, APTBBatSeq=APTB.BatchSeq, APTB.ExpMth, APTB.APTrans, APTB.APRef, 
 	APTB.Description, APTB.InvDate, APTB.Gross, /*APTB.Retainage, APTB.PrevPaid, APTB.PrevDisc, 
 	APTB.Balance,  APTB.DiscTaken fields only updated after printing check (issue 17571), remmed out 6/6/02 dh */
 	DB.CurrentAmt, DB.DiscTaken, HQCO.HQCo, HQName=HQCO.Name,  APSupName=APVMSup.Name, 
 	APTH.DueDate,
 	#comp.SLCompliance, #comp.POCompliance, #comp.APCompliance, #comp.SLCompDesc, #comp.POCompDesc, #comp.APCompDesc
     FROM APPB APPB 
     	JOIN APTB APTB with (nolock) ON 
 		APPB.Co=APTB.Co AND 
 		APPB.Mth=APTB.Mth AND 
 		APPB.BatchId=APTB.BatchId 
 		AND APPB.BatchSeq=APTB.BatchSeq
     -- Added derived table DB to get Current and DiscTaken 6/6/02 DH issue 17571
 	JOIN (Select Co, Mth, BatchId, BatchSeq, ExpMth, APTrans, CurrentAmt=sum(Amount),
                      DiscTaken=sum(DiscTaken) 
           	From APDB
           	Group By Co, Mth, BatchId, BatchSeq, ExpMth, APTrans) as DB ON 
   			APTB.Co=DB.Co and 
 			APTB.Mth=DB.Mth and 
 			APTB.BatchId=DB.BatchId and 
 			APTB.BatchSeq=DB.BatchSeq and 
 			APTB.ExpMth=DB.ExpMth and 
 			APTB.APTrans=DB.APTrans
 	JOIN HQCO HQCO with (nolock) ON  
 		APPB.Co=HQCO.HQCo
 	LEFT OUTER JOIN APVM APVMSup with (nolock) ON 
 		APPB.VendorGroup=APVMSup.VendorGroup AND  
 		APPB.Supplier=APVMSup.Vendor
     	JOIN APVM APVM with (nolock) ON  
 		APPB.VendorGroup=APVM.VendorGroup AND  
 		APPB.Vendor=APVM.Vendor
 	JOIN APTH APTH with (nolock) ON   
 		APTB.Co=APTH.APCo AND  
 		APTB.ExpMth=APTH.Mth AND 
  		APTB.APTrans=APTH.APTrans
     	LEFT OUTER JOIN #comp with (nolock) ON 
 		APTB.BatchSeq=#comp.BatchSeq and 
 		APTB.APTrans=#comp.APTrans
     WHERE APPB.Co=@Co 
           AND APPB.Mth= @PayMth 
           AND APPB.BatchId=@BatchId 
           AND APVM.Vendor >= @BegVendorName 
           AND APVM.Vendor <=@EndVendorName  
           AND APPB.VoidYN <> 'Y'
     ORDER BY
       APPB.Co, APPB.Mth,  APPB.BatchId,  APPB.PayMethod,  APPB.ChkType, APVendorName,
       APPB.BatchSeq,  APTB.ExpMth,  APTB.APTrans

GO
GRANT EXECUTE ON  [dbo].[brptCheckPrev] TO [public]
GO
