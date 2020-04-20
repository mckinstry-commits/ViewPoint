SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/***Add PRTB.Type as "TimecardType" into temp table and output to be able to add group for Issue 19778 05/13/03 NF***/
   /*  Issue 25904 Added with(nolock) to the from and join statements NF 11/11/04 */
   
    CREATE    proc [dbo].[brptEarningsTots]
     
     as
     create table #EarningsTotals
         (Co              tinyint              NULL,
         Mth             smalldatetime       Null,
         BatchId         int            NULL,
         BatchSeq        int                 Null,
         BatchTransType    char(1)       Null,
         PRGroup             int     Null,
         PREndDate       smalldatetime       null,
         TimecardType	char(1)    null,
         EarnCode        int         null,
         Hours           decimal(16,2)       Null,
         Amt             decimal(16,2)        Null,
         OldEarnCode     int         null,
         OldHours        decimal(16,2)       Null,
         OldAmt          decimal(16,2)       Null,
         RptEarnCode     int         null,
         RptHours        decimal(16,2)       Null,
         RptAmt        decimal(16,2)       Null
         )
     
     /* insert Earn Code */
     insert into #EarningsTotals
     (Co , Mth , BatchId , BatchSeq, BatchTransType, PRGroup,  PREndDate, TimecardType, EarnCode , Hours, Amt,RptEarnCode, RptHours, RptAmt  )
     
     Select PRTB.Co , PRTB.Mth , PRTB.BatchId , PRTB.BatchSeq, PRTB.BatchTransType, HQBC.PRGroup,  HQBC.PREndDate,
     PRTB.Type, PRTB.EarnCode , PRTB.Hours, PRTB.Amt,PRTB.EarnCode , PRTB.Hours, PRTB.Amt
     
     FROM PRTB with(nolock)
     join HQBC with(nolock)
     	on PRTB.Co=HQBC.Co and PRTB.Mth=HQBC.Mth and PRTB.BatchId=HQBC.BatchId
     
      where BatchTransType<>'D'
     
     /* insert Earn Code */
     insert into #EarningsTotals
     (Co , Mth , BatchId , BatchSeq, BatchTransType, PRGroup,  PREndDate, TimecardType, OldEarnCode , OldHours, OldAmt,
     RptEarnCode , RptHours, RptAmt)
     Select PRTB.Co , PRTB.Mth , PRTB.BatchId , PRTB.BatchSeq, PRTB.BatchTransType, HQBC.PRGroup,  HQBC.PREndDate,
     PRTB.Type, PRTB.OldEarnCode , PRTB.OldHours, PRTB.OldAmt, PRTB.OldEarnCode,0-(PRTB.OldHours), 0-(PRTB.OldAmt)
     
     FROM PRTB with(nolock)
     join HQBC with(nolock)
     	on PRTB.Co=HQBC.Co and PRTB.Mth=HQBC.Mth and PRTB.BatchId=HQBC.BatchId
     
      Select a.Co, a.Mth, a.BatchId, a.BatchSeq, a.BatchTransType, a.PRGroup,  a.PREndDate, a.TimecardType,
     a.EarnCode , a.Hours, a.Amt,a.OldEarnCode,a.OldHours,a.OldAmt,a.RptEarnCode,a.RptHours,RptAmt,
     ECDesc=PREC.Description,DDUP.ShowRates
     
        from #EarningsTotals a with(nolock)
        Join PREC with(nolock)
        	on PREC.PRCo=a.Co and PREC.EarnCode=a.RptEarnCode
        join HQBC with(nolock)
        	on a.Co=HQBC.Co and a.Mth=HQBC.Mth and a.BatchId=HQBC.BatchId
        Left join DDUP with(nolock)
        	on HQBC.InUseBy=DDUP.VPUserName

GO
GRANT EXECUTE ON  [dbo].[brptEarningsTots] TO [public]
GO
