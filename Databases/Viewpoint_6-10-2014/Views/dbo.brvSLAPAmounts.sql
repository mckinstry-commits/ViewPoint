SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[brvSLAPAmounts] as select SLCo=APTL.APCo, APTL.SL, APTL.SLItem, APInvAmt=sum(Amount), APPaid=sum(case when Status>3 then Amount else 0 end)
    from APTL
    left join APTD on APTD.APCo=APTL.APCo and APTD.Mth=APTL.Mth and APTD.APTrans=APTL.APTrans and APTD.APLine=APTL.APLine
    group by APTL.APCo, APTL.SL, APTL.SLItem

GO
GRANT SELECT ON  [dbo].[brvSLAPAmounts] TO [public]
GRANT INSERT ON  [dbo].[brvSLAPAmounts] TO [public]
GRANT DELETE ON  [dbo].[brvSLAPAmounts] TO [public]
GRANT UPDATE ON  [dbo].[brvSLAPAmounts] TO [public]
GRANT SELECT ON  [dbo].[brvSLAPAmounts] TO [Viewpoint]
GRANT INSERT ON  [dbo].[brvSLAPAmounts] TO [Viewpoint]
GRANT DELETE ON  [dbo].[brvSLAPAmounts] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[brvSLAPAmounts] TO [Viewpoint]
GO
