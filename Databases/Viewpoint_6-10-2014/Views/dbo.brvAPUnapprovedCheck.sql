SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/* where APUR.Line <> -1*/
CREATE VIEW [dbo].[brvAPUnapprovedCheck]
/*************************************
* Used in AP Unapproved Invoice Update Check
*
* mod 2/6/08 Issue 30103 CR
* mod 2/12/08 Issue 123181 CR
* mod 7/22/08 issue 129028 CR(added APUL.MiscAmt, APUL.MiscYN, APUI.InvTotal and sumcheck)
* mod HH 6/18/12 D-05288 added SMCo, SMWorkOrder, Scope and SMJCCostType
*
**************************************/


AS
SELECT dbo.APUI.APCo, 
       ISNULL(CAST(dbo.APUL.Line AS char(5)), 'blank')     AS Line, 
       dbo.APUI.UIMth, 
       dbo.APUI.UISeq, 
       dbo.APUL.LineType, 
       dbo.APUL.ItemType, 
       ISNULL(CAST(dbo.APUL.JCCo AS Char(5)), 'blank')     AS JCCo, 
       ISNULL(dbo.APUL.Job, 'blank')                       AS Job, 
       ISNULL(dbo.APUL.Phase, 'blank')                     AS Phase, 
       ISNULL(CAST(dbo.APUL.JCCType AS Char(5)), 'blank')  AS CT, 
       ISNULL(dbo.APUL.WO, 'blank')                        AS WO, 
       ISNULL(CAST(dbo.APUL.WOItem AS Char(5)), 'blank')   AS WOItem, 
       ISNULL(dbo.APUL.PO, 'blank')                        AS PO, 
       ISNULL(CAST(dbo.APUL.POItem AS char(5)), 'blank')   AS POItem, 
       ISNULL(dbo.APUL.SL, 'blank')                        AS SL, 
       ISNULL(CAST(dbo.APUL.SLItem AS char(5)), 'blank')   AS SLItem, 
       ISNULL(CAST(dbo.APUL.INCo AS char(5)), 'blank')     AS INCo, 
       ISNULL(dbo.APUL.Loc, 'blank')                       AS INLoc, 
       ISNULL(dbo.APUL.Material, 'blank')                  AS Material, 
       ISNULL(CAST(dbo.APUL.EMCo AS char(5)), 'blank')     AS EMCo, 
       ISNULL(dbo.APUL.Equip, 'blank')                     AS Equip, 
       ISNULL(dbo.APUL.CostCode, 'blank')                  AS CostCode, 
       ISNULL(CAST(dbo.APUL.EMCType AS char(5)), 'blank')  AS EMCType, 
       ISNULL(CAST(dbo.APUL.EMGroup AS char(5)), 'blank')  AS EMGroup, 
       ISNULL(CAST(dbo.APUL.GLCo AS char(5)), 'blank')     AS GLCo, 
       ISNULL(dbo.APUL.GLAcct, 'blank')                    AS GLAcct, 
       ISNULL(CAST(dbo.APUR.Reviewer AS char(5)), 'blank') AS Reviewer, 
       ISNULL(CAST(dbo.APUL.SMCo AS Char(5)), 'blank')     AS SMCo, 
       ISNULL(CAST(dbo.APUL.SMWorkOrder AS char(5)), 'blank')   AS SMWorkOrder, 
       ISNULL(CAST(dbo.APUL.Scope AS char(5)), 'blank')   AS Scope, 
       ISNULL(CAST(dbo.APUL.SMJCCostType AS char(5)), 'blank')   AS SMJCCostType, 
       dbo.APUL.GrossAmt, 
       dbo.APUL.Notes, 
       LineSeqTotal=T.LineSeqTotal, 
       Isnull(P.PO, 'blank')                               as POPO, 
       POMth=P.InUseMth, 
       POBatch=P.InUseBatchId, 
       dbo.APUL.MiscAmt, 
       dbo.APUL.MiscYN, 
       Isnull(S.SL, 'blank')                               as SLHDSL, 
       SLMth=S.InUseMth, 
       SLBatch=S.InUseBatchId, 
       T.InvTotal, 
       ( case 
           when T.InvTotal <> T.LineSeqTotal then 1 
           else 0 
         end )                                             as sumcheck 
FROM   dbo.APUI 
       LEFT OUTER JOIN dbo.APUL 
                    ON dbo.APUL.APCo = dbo.APUI.APCo 
                       AND dbo.APUL.UIMth = dbo.APUI.UIMth 
                       AND dbo.APUL.UISeq = dbo.APUI.UISeq 
       LEFT OUTER JOIN dbo.APUR 
                    ON dbo.APUL.APCo = dbo.APUR.APCo 
                       AND dbo.APUL.UIMth = dbo.APUR.UIMth 
                       AND dbo.APUL.UISeq = dbo.APUR.UISeq 
                       AND dbo.APUL.Line = dbo.APUR.Line 
                       AND dbo.APUR.Line <> -1 
       left join (select POHD.POCo, 
                         POHD.PO, 
                         POHD.InUseMth, 
                         POHD.InUseBatchId 
                  from   POHD 
                  where  POHD.InUseBatchId is not null) as P 
              on P.POCo = APUL.APCo 
                 and P.PO = APUL.PO 
       left join (select SLHD.SLCo, 
                         SLHD.SL, 
                         SLHD.InUseMth, 
                         SLHD.InUseBatchId 
                  from   SLHD 
                  where  SLHD.InUseBatchId is not null) as S 
              on S.SLCo = APUL.APCo 
                 and S.SL = APUL.SL 
       left join (select APUI.APCo, 
                         APUI.UIMth, 
                         APUI.UISeq, 
                         LineSeqTotal=( Sum(APUL.GrossAmt) + sum(case when 
                                        APUL.MiscYN 
                                        = 'Y' then 
                                        APUL.MiscAmt else 0 
                                                     end) ), 
                         APUI.InvTotal 
                  from   APUI 
                         LEFT OUTER JOIN dbo.APUL 
                                      ON dbo.APUL.APCo = dbo.APUI.APCo 
                                         AND dbo.APUL.UIMth = dbo.APUI.UIMth 
                                         AND dbo.APUL.UISeq = dbo.APUI.UISeq 
                  Group  by APUI.APCo, 
                            APUI.UIMth, 
                            APUI.UISeq, 
                            APUI.InvTotal) as T 
              on T.APCo = APUI.APCo 
                 and T.UIMth = APUI.UIMth 
                 and T.UISeq = APUI.UISeq 

GO
GRANT SELECT ON  [dbo].[brvAPUnapprovedCheck] TO [public]
GRANT INSERT ON  [dbo].[brvAPUnapprovedCheck] TO [public]
GRANT DELETE ON  [dbo].[brvAPUnapprovedCheck] TO [public]
GRANT UPDATE ON  [dbo].[brvAPUnapprovedCheck] TO [public]
GRANT SELECT ON  [dbo].[brvAPUnapprovedCheck] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvAPUnapprovedCheck] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvAPUnapprovedCheck] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvAPUnapprovedCheck] TO [Viewpoint]
GO
