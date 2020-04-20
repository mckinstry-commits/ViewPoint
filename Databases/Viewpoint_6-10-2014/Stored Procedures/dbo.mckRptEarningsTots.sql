SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[mckRptEarningsTots]
AS
/*******************************************************************************************************
* mckRptEarningsTots                                                                                   *
*   - This proc is based on proc [brptEarningsTots] except that it does not return rows when           *
*     EarnCode is null. (Hours is usually null too when Earncode is null but not checked)              *
*     Used in the subreport of MCKPRBatchAudit.rpt                                                     *
*                                                                                                      *
* Date      By          Comment                                                                        *
* =======   =========== ======================================================                         *
* 20140409  ZachF       Created                                                                        *
*                                                                                                      *
*                                                                                                      *
*******************************************************************************************************/
BEGIN

CREATE TABLE #EarningsTotals(
    Co             tinyint null
   ,Mth            smalldatetime null
   ,BatchId        int null
   ,BatchSeq       int null
   ,BatchTransType char(1) null
   ,PRGroup        int null
   ,PREndDate      smalldatetime null
   ,TimecardType   char(1) null
   ,EarnCode       int null
   ,Hours          decimal(16,2) null
   ,Amt            decimal(16,2) null
   ,OldEarnCode    int null
   ,OldHours       decimal(16,2) null
   ,OldAmt         decimal(16,2) null
   ,RptEarnCode    int null
   ,RptHours       decimal(16,2) null
   ,RptAmt         decimal(16,2) null
)
     
/* Insert Earn Code */
INSERT
   #EarningsTotals(
    Co
   ,Mth
   ,BatchId
   ,BatchSeq
   ,BatchTransType
   ,PRGroup
   ,PREndDate
   ,TimecardType
   ,EarnCode
   ,Hours
   ,Amt
   ,RptEarnCode
   ,RptHours
   ,RptAmt
   )  
SELECT
    PRTB.Co
   ,PRTB.Mth
   ,PRTB.BatchId
   ,PRTB.BatchSeq
   ,PRTB.BatchTransType
   ,HQBC.PRGroup
   ,HQBC.PREndDate
   ,PRTB.Type
   ,PRTB.EarnCode
   ,PRTB.Hours
   ,PRTB.Amt
   ,PRTB.EarnCode
   ,PRTB.Hours
   ,PRTB.Amt
FROM
   PRTB WITH (READUNCOMMITTED)
   JOIN
      HQBC WITH (READUNCOMMITTED)
     	ON PRTB.Co = HQBC.Co
         AND PRTB.Mth = HQBC.Mth
         AND PRTB.BatchId = HQBC.BatchId
WHERE
   BatchTransType<>'D'

     
/* Insert Earn Code */
INSERT
   #EarningsTotals(
    Co
   ,Mth
   ,BatchId
   ,BatchSeq
   ,BatchTransType
   ,PRGroup
   ,PREndDate
   ,TimecardType
   ,OldEarnCode
   ,OldHours
   ,OldAmt
   ,RptEarnCode
   ,RptHours
   ,RptAmt
   )
SELECT
    PRTB.Co
   ,PRTB.Mth
   ,PRTB.BatchId
   ,PRTB.BatchSeq
   ,PRTB.BatchTransType
   ,HQBC.PRGroup
   ,HQBC.PREndDate
   ,PRTB.Type
   ,PRTB.OldEarnCode
   ,PRTB.OldHours
   ,PRTB.OldAmt
   ,PRTB.OldEarnCode
   ,0-(PRTB.OldHours)
   ,0-(PRTB.OldAmt)
FROM
   PRTB WITH (READUNCOMMITTED)
   JOIN
      HQBC WITH (READUNCOMMITTED)
         ON PRTB.Co = HQBC.Co
            AND PRTB.Mth = HQBC.Mth
            AND PRTB.BatchId = HQBC.BatchId
SELECT
    a.Co
   ,a.Mth
   ,a.BatchId
   ,a.BatchSeq
   ,a.BatchTransType
   ,a.PRGroup
   ,a.PREndDate
   ,a.TimecardType
   ,a.EarnCode
   ,a.Hours
   ,a.Amt
   ,a.OldEarnCode
   ,a.OldHours
   ,a.OldAmt
   ,a.RptEarnCode
   ,a.RptHours
   ,RptAmt
   ,ECDesc = PREC.Description
   ,DDUP.ShowRates
FROM
   #EarningsTotals a WITH (READUNCOMMITTED)
   JOIN
      PREC WITH (READUNCOMMITTED)
      ON PREC.PRCo = a.Co
         AND PREC.EarnCode = a.RptEarnCode
   JOIN
      HQBC WITH (READUNCOMMITTED)
         ON a.Co = HQBC.Co
            AND a.Mth = HQBC.Mth
            AND a.BatchId = HQBC.BatchId
   LEFT JOIN
      DDUP WITH (READUNCOMMITTED)
         ON HQBC.InUseBy = DDUP.VPUserName
WHERE
   a.EarnCode IS NOT NULL
END
GO
GRANT EXECUTE ON  [dbo].[mckRptEarningsTots] TO [public]
GO
