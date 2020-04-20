SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view [dbo].[vrvSLSubContractStatus] as
/* insert Change Order info for SubContract item */
/* Original Cost and Units exclude Backcharge Amts*/
Select SLIT.SLCo,SLIT.SL,SLIT.SLItem,SLIT.ItemType,Addon=Max(SLIT.Addon),AddonPct=Max(SLIT.AddonPct),
       SLADDesc=Max(SLAD.Description),SLITDesc=Max(SLIT.Description),SLIT.UM,
       SLIT.JCCo,SLIT.Job,SLIT.PhaseGroup,SLIT.Phase,SLIT.JCCType, SLIT.OrigCost,
       SLCDCurCost=sum(SLCD.ChangeCurCost), SLIT.OrigUnits, SLCDActDate=SLCD.ActDate,
       SLCDChgUnits=sum(SLCD.ChangeCurUnits), SLIT.OrigUnitCost, SLCDChgUC=sum(SLCD.ChangeCurUnitCost),
       InvDate='1/1/1950', APTLUnits=0,APTDAmt=0,APTDStatus=0, APTDPdDate='1/1/1950',APTDPayCat=0,
       APCORetPayType=0, APPCRetPayType=0, APTDDiscTaken=0



      FROM SLIT with(nolock)
      Left Join SLCD with(nolock) on SLCD.SLCo=SLIT.SLCo and SLCD.SL=SLIT.SL and SLCD.SLItem=SLIT.SLItem
      Left Join SLAD with(nolock) on SLAD.SLCo=SLIT.SLCo and SLAD.Addon=SLIT.Addon
      Join SLHD with(nolock) on SLHD.SLCo=SLIT.SLCo and SLHD.SL=SLIT.SL
     
      --where SLIT.SLCo=@SLCo and SLIT.SL>= @BeginSubContract and SLIT.SL<= @EndSubContract
      --and isnull(SLIT.Job,'') between @BeginJob and @EndJob
      --and isnull(SLHD.Vendor,0) between @BeginVendor and @EndVendor
        group by SLIT.SLCo,SLIT.SL,SLIT.SLItem,SLIT.ItemType, SLIT.Description,SLIT.UM,SLIT.JCCo,
      	SLIT.Job,SLIT.PhaseGroup,SLIT.Phase,SLIT.JCCType, SLIT.OrigCost, SLIT.OrigUnits,
      	SLIT.OrigUnitCost, SLCD.ActDate

Union all

 /* insert AP info for SubContract item */
         
      Select SLIT.SLCo,SLIT.SL,SLIT.SLItem,SLIT.ItemType,Max(SLIT.Addon),Max(SLIT.AddonPct),
      	Max(SLAD.Description), SLIT.Description,SLIT.UM,
      	SLIT.JCCo,SLIT.Job,SLIT.PhaseGroup,SLIT.Phase,SLIT.JCCType,0,0,0,'1/1/1950',0,0,0,
      	APTH.InvDate, APTL.Units, sum(APTD.Amount),APTD.Status, APTD.PaidDate, APTD.PayCategory,
        APCO.RetPayType, APPC.RetPayType, APTD.DiscTaken
  	
   
          FROM SLIT with(nolock)
      Join SLHD with(nolock) on SLHD.SLCo=SLIT.SLCo and SLHD.SL=SLIT.SL
      Left Join APTL with(nolock) on APTL.APCo=SLIT.SLCo and APTL.SL=SLIT.SL and APTL.SLItem=SLIT.SLItem
      Left Join APTD with(nolock) on APTD.APCo=APTL.APCo and APTD.Mth=APTL.Mth and APTD.APTrans=APTL.APTrans
      	and APTD.APLine=APTL.APLine
      Left Join APTH with(nolock) on APTH.APCo=APTL.APCo and APTH.Mth=APTL.Mth and APTH.APTrans=APTL.APTrans
      Left Join SLAD with(nolock) on SLAD.SLCo=SLIT.SLCo and SLAD.Addon=SLIT.Addon
      Left Join APCO with(nolock) on APCO.APCo=APTL.APCo
      Left Join APPC with(nolock) on APTD.APCo=APPC.APCo and APTD.PayCategory=APPC.PayCategory
     
      --where SLIT.SLCo=@SLCo and SLIT.SL>= @BeginSubContract and SLIT.SL<= @EndSubContract
        --and isnull(SLIT.Job,'') between @BeginJob and @EndJob
        --and isnull(SLHD.Vendor,0) between @BeginVendor and @EndVendor
      group by SLIT.SLCo,SLIT.SL,SLIT.SLItem,SLIT.ItemType,SLIT.Description,SLIT.UM,
      	SLIT.JCCo,SLIT.Job,SLIT.PhaseGroup,SLIT.Phase,SLIT.JCCType,APTL.APTrans,APTL.Units,
      	APTH.InvDate,APTD.Status, APTD.PaidDate, APTD.PayCategory, APCO.RetPayType, APPC.RetPayType,
        APTD.DiscTaken




GO
GRANT SELECT ON  [dbo].[vrvSLSubContractStatus] TO [public]
GRANT INSERT ON  [dbo].[vrvSLSubContractStatus] TO [public]
GRANT DELETE ON  [dbo].[vrvSLSubContractStatus] TO [public]
GRANT UPDATE ON  [dbo].[vrvSLSubContractStatus] TO [public]
GRANT SELECT ON  [dbo].[vrvSLSubContractStatus] TO [Viewpoint]
GRANT INSERT ON  [dbo].[vrvSLSubContractStatus] TO [Viewpoint]
GRANT DELETE ON  [dbo].[vrvSLSubContractStatus] TO [Viewpoint]
GRANT UPDATE ON  [dbo].[vrvSLSubContractStatus] TO [Viewpoint]
GO
