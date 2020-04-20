SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE           PROCEDURE [dbo].[bspHQAPEFTDetail]
     /************************************
       * Created: 09/11/01 MV
       * Modified: 10/09/01 MV - removed Mth selection criteria
   	* 			6/19/2 kb - issue #17687 - change for CTX format to get values 
   	* 			from APTB instead of APTL
    *		  	6/26/02 MV - #17687 - removed joins to APTL, APTH
   	*			09/08/04 MV - #25505 - include batch month in select statement
	*			11/28/06 MV = APEFT 6X recode
   	*
       * This SP is used in HQExport form frmAPEFTExport.
       * This SP returns the sum of the APTL invoice amounts and
       * record count for CTX detail records
       * Any changes here will require changes to the form.
       *
       ***********************************/
       (@apco bCompany, @month bMonth, @batchid bBatchID, @batchseq int)
     
      as
      set nocount on
     
     /* SELECT 'NetAmt' = (sum(a.GrossAmt) - sum(a.Retainage + Discount)), count (*)
         FROM bAPTL a JOIN bAPTH b ON a.APCo = b.APCo and a.Mth = b.Mth and a.APTrans = b.APTrans
         JOIN APTB c ON b.APCo=c.Co and b.InUseMth=c.Mth and b.InUseBatchId=c.BatchId and b.APTrans=c.APTrans
         WHERE b.APCo = @apco and b.InUseBatchId = @batchid and c.BatchSeq=@batchseq*/
   
   	/*SELECT 'NetAmt' = sum(c.Gross-c.Retainage-c.PrevPaid-c.PrevDisc-c.Balance-c.DiscTaken), count (*)
         FROM bAPTH b
         JOIN APTB c ON b.APCo=c.Co and b.InUseMth=c.Mth and b.InUseBatchId=c.BatchId and b.APTrans=c.APTrans
         WHERE b.APCo = @apco and b.InUseBatchId = @batchid and c.BatchSeq=@batchseq */ 
     
        -- per check stub detail, all required info comes from bAPTB.  
     	SELECT 'NetAmt' = sum(Gross-Retainage-PrevPaid-PrevDisc-Balance-DiscTaken), 'Count'=count (*)
         FROM APTB WHERE Co = @apco and Mth= @month and BatchId = @batchid and BatchSeq=@batchseq

GO
GRANT EXECUTE ON  [dbo].[bspHQAPEFTDetail] TO [public]
GO
