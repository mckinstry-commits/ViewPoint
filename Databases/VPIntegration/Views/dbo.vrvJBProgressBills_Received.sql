SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE View [dbo].[vrvJBProgressBills_Received]

/***
 Usage:  Returns JB Bill Numbers with Previous Received Amounts.  
		 Previous Received = receipts where the paid month/date is less than the invoice month/date of a JB Bill.
		 Previous amounts are also tracked by contract item (needed in case JB Bills are initialized by bill group
		 assigned to contract items.  View then summarizes the items by JB Bill.
		 
	     Used in the JB Progress Claim Report
 Created:  DH 10/21/10

*****/ 

as

/**Get AR Receipts by ApplyMth/ApplyTrans (AR Trans to which the receipt is applied)*/



With ARTLRecvd (ARCo, PaidMth, PaidDate, ApplyMth, ApplyTrans, ApplyLine, Received)  
  
as  
  
(Select ARTL.ARCo, ARTL.Mth, ARTH.TransDate, ARTL.ApplyMth, ARTL.ApplyTrans, ARTL.ApplyLine, sum(ARTL.Amount-ARTL.TaxAmount) as Received  
    From ARTL  
    Join ARTH on ARTH.ARCo = ARTL.ARCo and ARTH.Mth=ARTL.Mth and ARTH.ARTrans=ARTL.ARTrans  
    Where ARTH.ARTransType='P'     --Restrict to receipts applied   
    Group by ARTL.ARCo, ARTL.Mth, ARTH.TransDate, ARTL.ApplyMth, ARTL.ApplyTrans, ARTL.ApplyLine  
)
,

/**Return list of AR Trans linked to JB Bills.  Returns AR Transaction numbers for both regular and released retainage invoices**/
JBInterfacedBills (JBCo, BillMonth, InvDate, BillNumber, ARTrans)

as

(select JBCo, BillMonth, InvDate, BillNumber, ARTrans From JBIN Where ARTrans is not null

  union all

--AR Release Retainage transaction
 select JBCo, BillMonth, InvDate, BillNumber, ARRelRetgCrTran From JBIN Where ARRelRetgCrTran is not null),
  
  
/*Select both Receipts applied to bills and JB invoices by Bill Number on separate rows*/
BillsWithReceipts (JCCo, Customer, Contract, Item, InvoiceORPaidMth, InvoiceORPaidDate, BillMonth, BillNumber, TransType, AmtDueLessTax, Received)  
  
as  
  
(
select    ARTL.JCCo
  , ARTH.Customer  
  , ARTL.Contract  
  , ARTL.Item
  , ARTLRecvd.PaidMth
  , ARTLRecvd.PaidDate
  , j.BillMonth  
  , j.BillNumber
  , 'P' as TransType  --Payment
  , 0 as AmtDueLessTax
  , sum(ARTLRecvd.Received*-1) as Received  
  From ARTLRecvd  
  
  
 Join ARTL
		ON  ARTL.ARCo = ARTLRecvd.ARCo
		AND ARTL.Mth = ARTLRecvd.ApplyMth   
		AND ARTL.ARTrans = ARTLRecvd.ApplyTrans
		AND ARTL.ARLine = ARTLRecvd.ApplyLine
 Join ARTH 
		ON  ARTH.ARCo = ARTL.ARCo
		AND ARTH.Mth = ARTL.Mth
		AND ARTH.ARTrans = ARTL.ARTrans		
 
 /*Join limits receipts only applied to transactions that originated from JB*/
 Join JBInterfacedBills j
		ON  j.JBCo = ARTL.ARCo
		AND j.BillMonth = ARTL.Mth
		AND j.ARTrans = ARTL.ARTrans
 
 
Group by ARTL.JCCo  
  , ARTH.Customer
  , ARTL.Contract 
  , ARTL.Item
  , ARTLRecvd.PaidMth
  , ARTLRecvd.PaidDate 
  , j.BillMonth
  , j.BillNumber

union all

Select    JBIN.JBCo
		, JBIN.Customer
		, JBIN.Contract
		, JBIT.Item
		, JBIN.BillMonth
		, JBIN.InvDate
		, JBIN.BillMonth
		, JBIN.BillNumber
		, 'I' as TransType --Invoice
		, JBIT.AmountDue - isnull(JBIT.TaxAmount,0)  as BilledLessTax
		, 0 as Received
From JBIN
Join JBIT 
	ON  JBIT.JBCo = JBIN.JBCo
	AND	JBIT.BillMonth = JBIN.BillMonth
	AND JBIT.BillNumber = JBIN.BillNumber

 
),

/*Select JB Invoices and Receipts applied to JB Invoices and generate a unique row number
  Row Number is ordered invoice or paid month/date, whichever is earlier*/
BillsWithReceiptsByDate (JCCo, Customer, Contract, Item, InvoiceORPaidMth, InvoiceORPaidDate, BillMonth, BillNumber, TransType, RowNumber, AmtDueLessTax, Received)

as


(Select	  JCCo
		, Customer
		, Contract
		, Item
		, InvoiceORPaidMth
		, InvoiceORPaidDate
		, BillMonth
		, BillNumber
		, TransType
		, Row_Number () OVER (Partition by JCCo, Customer, Contract, Item 
							  Order by JCCo, Customer, Contract, Item, InvoiceORPaidMth, InvoiceORPaidDate) as RowNumber
		, AmtDueLessTax
		, Received

 From BillsWithReceipts)
 
 --select * From BillsWithReceiptsByDate
 

/**Select Results:  Sums the previous receipts by JB Invoice **/  
  
select    CurrentBill.JCCo  
  , CurrentBill.Contract  
  , CurrentBill.BillMonth  
  , CurrentBill.BillNumber 
  , sum(PrevBill.Received) as Received_Previous  
From BillsWithReceiptsByDate CurrentBill  
  
Left Join BillsWithReceiptsByDate PrevBill   
 ON  PrevBill.JCCo = CurrentBill.JCCo  
 AND PrevBill.Customer = CurrentBill.Customer
 AND PrevBill.Contract = CurrentBill.Contract  
 AND PrevBill.Item = CurrentBill.Item  
 AND CurrentBill.TransType = 'I'
 AND PrevBill.RowNumber < CurrentBill.RowNumber  
   
   
  
Group By  CurrentBill.JCCo  
  , CurrentBill.Contract 
  , CurrentBill.BillMonth  
  , CurrentBill.BillNumber 



			   



GO
GRANT SELECT ON  [dbo].[vrvJBProgressBills_Received] TO [public]
GRANT INSERT ON  [dbo].[vrvJBProgressBills_Received] TO [public]
GRANT DELETE ON  [dbo].[vrvJBProgressBills_Received] TO [public]
GRANT UPDATE ON  [dbo].[vrvJBProgressBills_Received] TO [public]
GO
