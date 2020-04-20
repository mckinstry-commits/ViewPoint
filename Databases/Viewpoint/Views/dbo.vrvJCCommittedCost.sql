SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





/****** Object:  View [dbo].[vrvJCCommittedCost]    Script Date: 10/05/2010 08:49:54 ******/


CREATE view [dbo].[vrvJCCommittedCost] 

/*****
 Usage:  View returns PO, SL, and MO data for the JC Committed Cost Detail report.
 Mod:  DH 10/5/2010 Issue 133470:  Modified View to return Current and Remaining Amounts from JCCD rather than
					  selecting from PO,SL,IN views.  Also, modified tax calculations to inlcude only JC
					  Committed Tax, which excludes GST.
	   HH 4/18/2012	Issue 145144:  changed vrvJCCommittedCost.RecvdNotInvoiced = (r.RecvdCost+r.RecvdTax) + j.Invoiced 
								   since j.Invoiced comes in as negative 

                      
******/ 


as

/*Get JC Committed Cost Data from JCCD*/

With JCCmtd (JCCo, Job, PhaseGroup, Phase, CostType
			 , APCo, VendorGroup, Vendor, PO, POItem, SL, SLItem, INCo, MO, MOItem
			 , TotalCmtdCost, RemainCmtdCost
			 , TotalCmtdUnits, TotalCmtdTax, RemCmtdTax
			 , Invoiced)
			 

as

(Select JCCD.JCCo, JCCD.Job, JCCD.PhaseGroup, JCCD.Phase, JCCD.CostType
		, JCCD.APCo, JCCD.VendorGroup, JCCD.Vendor, JCCD.PO, JCCD.POItem, JCCD.SL, JCCD.SLItem
		, JCCD.INCo, JCCD.MO, JCCD.MOItem
		, sum(JCCD.TotalCmtdCost), sum(JCCD.RemainCmtdCost)
		, sum(JCCD.TotalCmtdUnits), sum(JCCD.TotalCmtdTax), sum(JCCD.RemCmtdTax)
		, sum(case when JCCD.Source = 'AP Entry' then JCCD.RemainCmtdCost else 0 end) /*Invoiced*/
 From JCCD		
 Where JCCD.PO is not null or JCCD.SL is not null or JCCD.MO is not null
 Group By JCCD.JCCo, JCCD.Job, JCCD.PhaseGroup, JCCD.Phase, JCCD.CostType
		, JCCD.APCo, JCCD.VendorGroup, JCCD.Vendor, JCCD.PO, JCCD.POItem, JCCD.SL, JCCD.SLItem
		, JCCD.INCo, JCCD.MO, JCCD.MOItem
),

/*Select Receipts from PORD.  If Post Receipt on Expense option is not selected in PO Comp Params,
  data only exists in PORD*/

Receipts (POCo, PO, POItem
		 , RecvdCost
		 , RecvdTax)

as

(Select PORD.POCo, PORD.PO, PORD.POItem
		, sum(PORD.RecvdCost) as RecvdCost
		/*Received Tax = Received Cost * TaxRate (excluding GST)*/
		, sum(PORD.RecvdCost)*(max(POIT.TaxRate) - max(POIT.GSTRate)) as RecvdTax
	From PORD
	Join POIT on POIT.POCo=PORD.POCo and POIT.PO=PORD.PO and POIT.POItem=PORD.POItem
	Group By PORD.POCo, PORD.PO, PORD.POItem),

/*Unapproved Invoices with PO's*/	
	
UnapprovedPO (APCo, PO, POItem, UnapprovedAP, MiscYN, MiscAmt, TaxType, TaxAmt, APDate)

as

(select APUL.APCo, APUL.PO, APUL.POItem, Amount=sum(APUL.GrossAmt), MiscYN=APUL.MiscYN, MiscAmt=APUL.MiscAmt,
        TaxType=APUL.TaxType, TaxAmt=sum(APUL.TaxAmt), InvDate=APUI.InvDate
from APUL
join APUI with (nolock) on APUL.APCo=APUI.APCo and APUL.UIMth=APUI.UIMth and APUL.UISeq=APUI.UISeq
where APUL.PO is not null
group by APUL.APCo, APUL.PO, APUL.POItem, APUL.MiscYN, APUL.MiscAmt, APUL.TaxType, APUL.TaxAmt,APUI.InvDate),

/*Unapproved Invoices with SL's*/

UnapprovedSL (APCo, SL, SLItem, UnapprovedAP, MiscYN, MiscAmt, TaxType, TaxAmt, APDate)

as

(select APUL.APCo, APUL.SL, APUL.SLItem, Amount=sum(APUL.GrossAmt),MiscYN=APUL.MiscYN, MiscAmt=APUL.MiscAmt,
TaxType=APUL.TaxType, TaxAmt=sum(APUL.TaxAmt), InvDate=APUI.InvDate
from APUL
join APUI with (nolock) on APUL.APCo=APUI.APCo and APUL.UIMth=APUI.UIMth and APUL.UISeq=APUI.UISeq
where APUL.SL is not null
group by APUL.APCo, APUL.SL, APUL.SLItem, APUL.MiscYN, APUL.MiscAmt, APUL.TaxType, APUL.TaxAmt,APUI.InvDate)

/*Final Data set for the Report*/
Select    1 as Source
		, j.JCCo as Company
		, j.PO
		, j.POItem
		, POIT.ItemType as POItemType
		, j.SL
		, j.SLItem
		, SLIT.ItemType as SLItemType
		, j.MO
		, j.MOItem
		, INMO.Description as MODesc
		, POHD.Description as PODesc
		, SLHD.Description as SLDesc
		, case when j.PO is not null then POHD.OrderDate
			   when j.SL is not null then SLHD.OrigDate
			   when j.MO is not null then INMO.OrderDate
		   end as Date
		, case when j.PO is not null then POIT.UM
			   when j.SL is not null then SLIT.UM
			   when j.MO is not null then INMI.UM
		   end as UM
		, j.Vendor
		, APVM.Name
		, j.JCCo     		
		, j.Job
		, j.PhaseGroup
		, j.Phase
		, j.CostType as JCCType
		, case when j.PO is not null then POIT.OrigUnits
			   when j.SL is not null then SLIT.OrigUnits
			   when j.MO is not null then INMI.OrderedUnits
		   end as OrigUnits
		, case when j.PO is not null then POIT.OrigCost
			   when j.SL is not null then SLIT.OrigCost
			   when j.MO is not null then INMI.TotalPrice
		   end as OrigCost
		, case when j.PO is not null then POIT.OrigTax
			   when j.SL is not null then SLIT.OrigTax
			   when j.MO is not null then INMI.TaxAmt
		   end as OrigTax		   	  
		, j.TotalCmtdUnits as CurUnits
		, j.TotalCmtdCost as CurCost
		, j.TotalCmtdTax as CurTax
		, j.RemainCmtdCost as RemCost
		, j.RemCmtdTax as RemTax
		/*Unapproved AP Amount*/
		, case when uPO.PO is not null then uPO.UnapprovedAP
			   when uSL.SL is not null then uSL.UnapprovedAP
		  else 0 end as UnapprovedAP	  
		  /*Unapproved MiscYN*/
		, case when uPO.PO is not null then uPO.MiscYN
			   when uSL.SL is not null then uSL.MiscYN
		  else Null end as MiscYN
		  
		, case when uPO.PO is not null then uPO.MiscAmt
			   when uSL.SL is not null then uSL.MiscAmt
		  else 0 end as MiscAmt  
		/*Unapproved TaxType*/
		, case when uPO.PO is not null then uPO.TaxType
			   when uSL.SL is not null then uSL.TaxType
		  else Null end as TaxType
		/*Unapproved Tax */  
		, case when uPO.PO is not null then uPO.TaxAmt
			   when uSL.SL is not null then uSL.TaxAmt
		  else 0 end as TaxAmt
		/*Unapproved Invoice Date*/  
		, case when uPO.PO is not null then uPO.APDate
			   when uSL.SL is not null then uSL.APDate
		  else Null end as APDate
		
		, r.RecvdCost + r.RecvdTax as Receipts /*Receipts include Tax*/
		, j.Invoiced /*AP Invoices from JCCD*/
		, case when isnull(r.RecvdCost,0)>0
				then (r.RecvdCost+r.RecvdTax) + j.Invoiced /* + because j.Invoiced comes in as negative */
		  else 0 end as RecvdNotInvoiced		
From JCCmtd j
Left Join POHD ON
		POHD.POCo = j.APCo
	AND POHD.PO = j.PO
Left Join SLHD ON
		SLHD.SLCo = j.APCo
	AND SLHD.SL = j.SL
Left Join INMO ON
		INMO.INCo = j.INCo
	AND INMO.MO = j.MO
Left Join POIT ON
		POIT.POCo = j.APCo
	AND POIT.PO = j.PO
	AND POIT.POItem = j.POItem
Left Join SLIT ON
		SLIT.SLCo = j.APCo
	AND SLIT.SL = j.SL
	AND SLIT.SLItem = j.SLItem
Left Join INMI ON
		INMI.INCo = j.INCo
	AND INMI.MO = j.MO
	AND INMI.MOItem = j.MOItem

Left Join APVM ON
		APVM.VendorGroup = j.VendorGroup
	AND APVM.Vendor = j.Vendor
					
Left Join Receipts r ON
        r.POCo = j.APCo
	AND r.PO = j.PO
	AND r.POItem = j.POItem
	
Left Join UnapprovedPO uPO ON
		uPO.APCo = j.APCo
	AND uPO.PO = j.PO
	AND uPO.POItem = j.POItem

Left Join UnapprovedSL uSL ON
		uSL.APCo = j.APCo
	AND uSL.SL = j.SL
	AND uSL.SLItem = j.SLItem	







GO
GRANT SELECT ON  [dbo].[vrvJCCommittedCost] TO [public]
GRANT INSERT ON  [dbo].[vrvJCCommittedCost] TO [public]
GRANT DELETE ON  [dbo].[vrvJCCommittedCost] TO [public]
GRANT UPDATE ON  [dbo].[vrvJCCommittedCost] TO [public]
GO
